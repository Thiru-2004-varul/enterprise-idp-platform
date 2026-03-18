# Enterprise Internal Developer Platform

[![Terraform Plan](https://github.com/Thiru-2004-varul/enterprise-idp-platform/actions/workflows/terraform.yml/badge.svg)](https://github.com/Thiru-2004-varul/enterprise-idp-platform/actions/workflows/terraform.yml)
![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-7B42BC)
![AWS EKS](https://img.shields.io/badge/AWS-EKS%201.29-FF9900)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5)
![Region](https://img.shields.io/badge/Region-ap--south--1-green)

A production-grade Internal Developer Platform on AWS that provides development teams with secure, isolated Kubernetes environments. Infrastructure is fully managed through Terraform modules. Developer access is enforced through Kubernetes RBAC. All infrastructure changes are validated through a plan-only CI/CD pipeline before human review.

---

## Architecture
```
                         Internet
                            |
               ┌────────────────────────┐
               │  Application Load      │
               │  Balancer (public)     │
               └────────────────────────┘
                  AZ-a           AZ-b
               [pub sub]      [pub sub]
                  |                |
            [NAT GW]          [NAT GW]
                  |                |
               [priv sub]    [priv sub]
            ┌──────────────────────────┐
            │     EKS Control Plane    │
            │      (managed by AWS)    │
            └──────────────────────────┘
                  |                |
           [Worker Node]    [Worker Node]
           Private AZ-a     Private AZ-b
                  |
      ┌───────────┼───────────┐
  [dev ns]  [staging ns]  [prod ns]
```

---

## Repository Structure
```
enterprise-idp-platform/
├── .github/
│   └── workflows/
│       └── terraform.yml          # Plan on PR, never auto-apply
├── infrastructure/
│   ├── modules/
│   │   ├── vpc/                   # VPC, subnets, IGW, NAT, route tables
│   │   ├── security/              # ALB, EC2, RDS security groups
│   │   ├── iam/                   # Cluster, node, developer IAM roles
│   │   └── eks/                   # EKS cluster + managed node group
│   ├── environments/
│   │   ├── dev/                   # Dev-specific tfvars and wiring
│   │   ├── staging/               # Staging-specific tfvars and wiring
│   │   └── prod/                  # Prod-specific tfvars and wiring
│   ├── main.tf                    # Root — calls all modules
│   ├── variables.tf               # Input variables with descriptions
│   ├── outputs.tf                 # VPC ID, EKS name, subnet IDs
│   └── versions.tf                # Terraform + provider constraints
└── k8s/
    ├── namespaces/
    │   ├── namespaces.yaml        # dev, staging, prod namespaces
    │   └── resource-quotas.yaml   # CPU, memory, pod limits per namespace
    └── rbac/
        └── developer-rbac.yaml    # Role + RoleBinding for dev namespace
```

---

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured — `aws configure`
- kubectl
- AWS account with permissions for EKS, VPC, IAM, EC2

---

## Usage

### 1. Clone
```bash
git clone https://github.com/Thiru-2004-varul/enterprise-idp-platform.git
cd enterprise-idp-platform
```

### 2. Configure credentials

`.tfvars` files are gitignored and must never be committed. Each environment contains a `terraform.tfvars.example` with all required keys. Copy and fill in:
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
```

> EKS control plane provisions in 15–20 minutes.

### 5. Configure cluster access
```bash
aws eks update-kubeconfig \
  --name dev-idp-cluster \
  --region ap-south-1

kubectl get nodes
kubectl apply -f ../../k8s/namespaces/
kubectl apply -f ../../k8s/rbac/
kubectl get resourcequota -A
```

### 6. Tear down
```bash
terraform destroy -var-file=terraform.tfvars
```

---

## Environments

| | dev | staging | prod |
|---|---|---|---|
| AZs | 2 | 2 | 3 |
| Node type | t3.medium | t3.medium | t3.medium |
| Nodes | 1 | 1 | 1–3 |
| CPU quota | 4 | 8 | 16 |
| Memory quota | 4Gi | 8Gi | 16Gi |
| Pod limit | 10 | 20 | 50 |

---

## Security

- Worker nodes in private subnets — not reachable from internet
- Separate least-privilege IAM roles for cluster, nodes, and developers
- Kubernetes RBAC scoped per namespace — developers cannot access staging or prod
- `.tfvars` gitignored — no credentials or environment values in version control
- Security groups follow deny-by-default — only required ports open

---

## CI/CD

GitHub Actions runs `terraform validate` and `terraform plan` on every pull request. `terraform apply` is intentionally manual — infrastructure changes require human review before reaching any environment.

To add AWS credentials to GitHub Actions:
```
Settings → Secrets and variables → Actions → New repository secret

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

---

## Author

**Thiruvarul G** — AWS DevOps Engineer
[github.com/Thiru-2004-varul](https://github.com/Thiru-2004-varul)
