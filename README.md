# Enterprise Internal Developer Platform

[![Terraform Plan](https://github.com/Thiru-2004-varul/enterprise-idp-platform/actions/workflows/terraform.yml/badge.svg)](https://github.com/Thiru-2004-varul/enterprise-idp-platform/actions/workflows/terraform.yml)
![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-7B42BC)
![AWS EKS](https://img.shields.io/badge/AWS-EKS%201.29-FF9900)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5)
![Region](https://img.shields.io/badge/Region-ap--south--1-green)

> Production-grade Internal Developer Platform on AWS — modular Terraform infrastructure, isolated Kubernetes environments per team, RBAC-enforced access control, and plan-only CI/CD pipeline.

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
                 |
              Internet
          (outbound only)
```

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| Terraform | All infrastructure as modular reusable code |
| AWS EKS | Managed Kubernetes — AWS runs the control plane |
| AWS VPC | Isolated network across 2–3 AZs |
| AWS IAM | Least-privilege roles per component |
| Kubernetes RBAC | Namespace-scoped developer access |
| GitHub Actions | terraform plan on every PR — smart path detection |

---

## Repository Structure
```
enterprise-idp-platform/
├── .github/
│   └── workflows/
│       └── terraform.yml       # Plan on PR — triggers only for changed environment
├── infrastructure/
│   ├── modules/
│   │   ├── vpc/                # VPC, subnets, IGW, NAT, route tables
│   │   ├── security/           # ALB, EC2, RDS security groups
│   │   ├── iam/                # Cluster, node, developer IAM roles
│   │   └── eks/                # EKS cluster + managed node group
│   ├── environments/
│   │   ├── dev/                # 2 AZs · 1 node · CPU 4 · Mem 4Gi
│   │   ├── staging/            # 2 AZs · 1 node · CPU 8 · Mem 8Gi
│   │   └── prod/               # 3 AZs · 3 nodes · CPU 16 · Mem 16Gi
│   ├── main.tf                 # Root — wires all modules together
│   ├── variables.tf            # All inputs with descriptions
│   ├── outputs.tf              # VPC ID, EKS cluster name, subnet IDs
│   └── versions.tf             # Terraform + provider constraints
└── k8s/
    ├── namespaces/
    │   ├── namespaces.yaml     # dev, staging, prod namespace definitions
    │   └── resource-quotas.yaml # CPU, memory, pod limits per namespace
    └── rbac/
        └── developer-rbac.yaml # Role + RoleBinding for dev namespace
```

---

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured — `aws configure`
- kubectl
- AWS account — ap-south-1 region

---

## Usage

### 1. Clone
```bash
git clone https://github.com/Thiru-2004-varul/enterprise-idp-platform.git
cd enterprise-idp-platform
```

### 2. Set credentials

`.tfvars` files are gitignored — never commit them. Copy from example:
```bash
cp infrastructure/environments/dev/terraform.tfvars.example \
   infrastructure/environments/dev/terraform.tfvars
```

`terraform.tfvars.example`:
```hcl
aws_region           = "ap-south-1"
environment          = "dev"
enable_creation      = true
public_subnet_count  = 2
private_subnet_count = 2
```

### 3. Plan
```bash
cd infrastructure/environments/dev
terraform init
terraform plan -var-file=terraform.tfvars
```

### 4. Apply
```bash
terraform apply -var-file=terraform.tfvars
# EKS takes 15-20 min · costs ~Rs.17/hr · destroy when done
```

### 5. Connect kubectl
```bash
aws eks update-kubeconfig --name dev-idp-cluster --region ap-south-1
kubectl get nodes
kubectl apply -f ../../k8s/namespaces/
kubectl apply -f ../../k8s/rbac/
kubectl get resourcequota -A
```

### 6. Destroy
```bash
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

## Key Design Decisions

| Decision | Why |
|----------|-----|
| Worker nodes in private subnets | Not reachable from internet — ALB is the only entry point |
| Separate IAM role per component | Least privilege — cluster, nodes, devs each get only what they need |
| RBAC scoped per namespace | Developers cannot touch staging or prod |
| ResourceQuota on every namespace | Prevents one team consuming all cluster resources |
| Plan-only CI/CD | Every infrastructure change reviewed before touching AWS |
| Path-based pipeline triggers | Only affected environment plans run — dev change never triggers prod plan |
| `.tfvars` gitignored | No credentials or environment values ever committed |

---

## CI/CD

Pipeline triggers only when relevant paths change:

| Files changed | Jobs that run |
|---|---|
| `infrastructure/environments/dev/**` | Plan -- dev only |
| `infrastructure/environments/staging/**` | Plan -- staging only |
| `infrastructure/environments/prod/**` | Plan -- prod only |
| `infrastructure/modules/**` | All three plans |
| `README.md` or `.gitignore` | Nothing runs |

Add AWS credentials to GitHub → Settings → Secrets → Actions:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

---

## Security

- Worker nodes in private subnets — no direct internet access
- Separate least-privilege IAM roles for cluster, nodes, and developers
- Kubernetes RBAC scoped per namespace — developers cannot access other environments
- `.tfvars` gitignored — no secrets in version control
- Branch protection on main — all changes require PR and passing plan checks

---

## Author

**Thiruvarul G** — 
[github.com/Thiru-2004-varul](https://github.com/Thiru-2004-varul)
