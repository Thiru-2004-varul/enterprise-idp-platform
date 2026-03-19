# Enterprise Internal Developer Platform

[![Terraform Plan](https://github.com/Thiru-2004-varul/enterprise-idp-platform/actions/workflows/terraform.yml/badge.svg)](https://github.com/Thiru-2004-varul/enterprise-idp-platform/actions/workflows/terraform.yml)
![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-7B42BC)
![AWS EKS](https://img.shields.io/badge/AWS-EKS%201.29-FF9900)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5)
![Region](https://img.shields.io/badge/Region-ap--south--1-green)

> Production-grade Internal Developer Platform on AWS — modular Terraform infrastructure, isolated Kubernetes environments per team, RBAC-enforced access control, ECR-based image registry, and smart path-based CI/CD pipeline.

---

## Architecture
```
                    Internet
                       |
          [Application Load Balancer]
           Public Subnet AZ-a   AZ-b
                       |
          [EKS Control Plane — managed by AWS]
                 |              |
      [Worker Node AZ-a]  [Worker Node AZ-b]
          Private Subnet     Private Subnet
                 |
   [dev ns]  [staging ns]  [prod ns]
   CPU: 4    CPU: 8        CPU: 16
   Mem: 4Gi  Mem: 8Gi      Mem: 16Gi
   Pods: 10  Pods: 20      Pods: 50
                 |
          [NAT Gateway]
          (outbound only)
```

---

## How It Works
```
Developer writes code
      ↓
docker build → docker push → ECR (private image registry)
      ↓
kubectl apply → EKS API server
      ↓ IAM token → aws-auth → K8s group → RBAC checks
Worker node pulls image from ECR using IAM role
      ↓
Pod starts → reads config from ConfigMap
      ↓
App running in isolated namespace
```

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| Terraform | All AWS infrastructure as modular reusable code |
| AWS EKS | Managed Kubernetes — AWS runs the control plane |
| AWS VPC | Isolated network — worker nodes in private subnets |
| AWS IAM | Least-privilege roles for cluster, nodes, developers |
| AWS ECR | Private Docker image registry — IAM-based auth, no passwords |
| Kubernetes RBAC | Namespace-scoped access via aws-auth + RoleBinding |
| Kubernetes ConfigMap | Environment-specific config injected as env vars |
| Kubernetes ResourceQuota | Hard CPU, memory, pod limits per namespace |
| GitHub Actions | Smart path-based terraform plan on every PR |

---

## Access Control

| Person | IAM Role | K8s Group | Namespace Access |
|--------|----------|-----------|-----------------|
| DevOps (Thiru) | admin-role | platform-admins | All namespaces + cluster level |
| Developer (Ravi) | dev-developer-role | dev-developers | dev only |
| Senior Dev (Priya) | staging-developer-role | staging-developers | staging + prod |

**Identity flow:**
```
IAM User assumes IAM Role
      ↓ aws-auth ConfigMap maps
Kubernetes Group
      ↓ RoleBinding connects
Role permissions in specific namespace only
```

---

## Repository Structure
```
enterprise-idp-platform/
├── .github/
│   └── workflows/
│       └── terraform.yml        # Smart path-based CI/CD pipeline
├── app/
│   ├── app.py                   # Sample Flask application
│   ├── Dockerfile               # Container image definition
│   └── requirements.txt         # Python dependencies
├── infrastructure/
│   ├── modules/
│   │   ├── vpc/                 # VPC, subnets, IGW, NAT Gateway
│   │   ├── security/            # ALB, EC2, RDS security groups
│   │   ├── iam/                 # Cluster, node, developer IAM roles
│   │   ├── eks/                 # EKS cluster + managed node group
│   │   └── ecr/                 # ECR repository + lifecycle policy
│   ├── environments/
│   │   ├── dev/                 # 2 AZs · 1 node · CPU 4 · Mem 4Gi
│   │   ├── staging/             # 2 AZs · 1 node · CPU 8 · Mem 8Gi
│   │   └── prod/                # 3 AZs · 3 nodes · CPU 16 · Mem 16Gi
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
└── k8s/
    ├── namespaces/
    │   ├── namespaces.yaml
    │   └── resource-quotas.yaml
    ├── rbac/
    │   └── developer-rbac.yaml
    └── app/
        ├── configmap.yaml
        └── deployment.yaml
```

---

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured — `aws configure`
- kubectl installed
- Docker installed
- AWS account — ap-south-1 region

---

## Usage

### Deploy dev environment
```bash
cp infrastructure/environments/dev/terraform.tfvars.example \
   infrastructure/environments/dev/terraform.tfvars

cd infrastructure/environments/dev
terraform init
terraform apply -var-file=terraform.tfvars

aws eks update-kubeconfig --name dev-idp-cluster --region ap-south-1
kubectl apply -f ../../../k8s/namespaces/
kubectl apply -f ../../../k8s/rbac/
kubectl apply -f ../../../k8s/app/
```

### Deploy staging environment
```bash
cp infrastructure/environments/staging/terraform.tfvars.example \
   infrastructure/environments/staging/terraform.tfvars

cd infrastructure/environments/staging
terraform init
terraform apply -var-file=terraform.tfvars

aws eks update-kubeconfig --name staging-idp-cluster --region ap-south-1
kubectl apply -f ../../../k8s/namespaces/
kubectl apply -f ../../../k8s/rbac/
kubectl apply -f ../../../k8s/app/
```

### Deploy prod environment
```bash
cp infrastructure/environments/prod/terraform.tfvars.example \
   infrastructure/environments/prod/terraform.tfvars

cd infrastructure/environments/prod
terraform init
terraform apply -var-file=terraform.tfvars

aws eks update-kubeconfig --name prod-idp-cluster --region ap-south-1
kubectl apply -f ../../../k8s/namespaces/
kubectl apply -f ../../../k8s/rbac/
kubectl apply -f ../../../k8s/app/
```

### Add developer access
```bash
# Add IAM role to aws-auth after each environment apply
kubectl edit configmap aws-auth -n kube-system

# Dev developer
# - rolearn: arn:aws:iam::ACCOUNT_ID:role/dev-developer-role
#   username: developer
#   groups:
#     - dev-developers

# Staging developer
# - rolearn: arn:aws:iam::ACCOUNT_ID:role/staging-developer-role
#   username: developer
#   groups:
#     - staging-developers
```

### Build and push app image
```bash
cd app
docker build -t idp-app:v1.0 .

aws ecr get-login-password --region ap-south-1 | \
  docker login --username AWS --password-stdin \
  ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com

docker tag idp-app:v1.0 \
  ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/dev-idp-app:v1.0

docker push \
  ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/dev-idp-app:v1.0
```

### Verify RBAC
```bash
# dev-developers group — dev access only
kubectl auth can-i get pods -n dev \
  --as=any-developer --as-group=dev-developers
# → yes

kubectl auth can-i get pods -n prod \
  --as=any-developer --as-group=dev-developers
# → no
```

### Verify ConfigMap injection
```bash
kubectl exec -it <pod-name> -n dev -- env | grep APP_ENV
# → APP_ENV=dev
```

### Destroy when done
```bash
kubectl delete -f k8s/app/
kubectl delete -f k8s/rbac/
kubectl delete -f k8s/namespaces/

aws ecr delete-repository \
  --repository-name dev-idp-app \
  --force --region ap-south-1

cd infrastructure/environments/dev
terraform destroy -var-file=terraform.tfvars
```

---

## Environments

| | dev | staging | prod |
|---|---|---|---|
| AZs | 2 | 2 | 3 |
| Node type | t3.medium | t3.medium | t3.medium |
| Max nodes | 1 | 1 | 3 |
| CPU quota | 4 cores | 8 cores | 16 cores |
| Memory quota | 4Gi | 8Gi | 16Gi |
| Pod limit | 10 | 20 | 50 |

---

## CI/CD Behaviour

| Files changed | Jobs triggered |
|---|---|
| `infrastructure/environments/dev/**` | Plan -- dev only |
| `infrastructure/environments/staging/**` | Plan -- staging only |
| `infrastructure/environments/prod/**` | Plan -- prod only |
| `infrastructure/modules/**` | All three plans |
| `README.md` | Nothing runs |

Add AWS credentials to GitHub → Settings → Secrets → Actions:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

## Key Design Decisions

| Decision | Why |
|----------|-----|
| Worker nodes in private subnets | Not reachable from internet — ALB is the only entry point |
| Separate IAM role per environment | Least privilege — each team gets only their environment |
| aws-auth ConfigMap for identity | Maps IAM roles to K8s groups — identity controlled in code |
| ClusterRole + RoleBinding pattern | Define permissions once — bind per namespace — no duplication |
| ClusterRole + ClusterRoleBinding for DevOps | Admin needs cluster-level access — nodes, namespaces, PVs |
| ResourceQuota per namespace | Prevents one team consuming all cluster resources |
| ECR over DockerHub | Private registry — worker nodes pull using IAM, no passwords |
| One ECR repo, multiple image tags | Same image runs in all environments — only tag and config change |
| ConfigMap for app config | Same Docker image — different behaviour per environment |
| Plan-only CI/CD | Every infrastructure change reviewed before touching AWS |
| Path-based pipeline triggers | Only affected environment plans run — no unnecessary CI runs |

---

## Security

- Worker nodes in private subnets — no direct internet access
- Separate least-privilege IAM roles for cluster, nodes, per-environment developers
- aws-auth ConfigMap maps IAM roles to Kubernetes groups — version controlled
- RBAC scoped per namespace — developers cannot access other environments
- ClusterRole + ClusterRoleBinding only for DevOps lead
- ECR image scanning enabled — CVE vulnerabilities detected on every push
- `.tfvars` gitignored — no credentials in version control
- Branch protection on main — all changes require PR and passing pipeline checks

---

## Author

**Thiruvarul G** — 
[github.com/Thiru-2004-varul](https://github.com/Thiru-2004-varul)
