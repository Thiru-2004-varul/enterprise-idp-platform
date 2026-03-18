# Enterprise Internal Developer Platform

[![Terraform Plan](https://github.com/Thiru-2004-varul/enterprise-idp-platform/actions/workflows/terraform.yml/badge.svg)](https://github.com/Thiru-2004-varul/enterprise-idp-platform/actions/workflows/terraform.yml)
![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5-7B42BC)
![AWS EKS](https://img.shields.io/badge/AWS-EKS%201.29-FF9900)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.29-326CE5)

> Modular AWS platform that gives teams isolated, secure Kubernetes environments — provisioned entirely through Terraform.

---

## Architecture
```
Internet
    |
[ALB — Public Subnets]
    |
[EKS Control Plane — managed by AWS]
    |              |
[Worker AZ-a]  [Worker AZ-b]   ← Private Subnets
    |
[dev ns] · [staging ns] · [prod ns]
    |
[NAT Gateway] → Internet (outbound only)
```

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| Terraform | All infrastructure as modular code |
| AWS EKS | Managed Kubernetes control plane |
| AWS VPC | Isolated network across 2–3 AZs |
| AWS IAM | Least-privilege roles per component |
| Kubernetes RBAC | Namespace-scoped developer access |
| GitHub Actions | terraform plan on every PR |

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
| Separate IAM role per component | Least privilege — cluster, nodes, and devs each get only what they need |
| RBAC scoped per namespace | Developers cannot touch staging or prod |
| ResourceQuotas on every namespace | Prevents one team starving another team's workload |
| Plan-only CI/CD | Infrastructure changes require human review before apply |
| `.tfvars` gitignored | No credentials or environment values ever committed |

---

## CI/CD

- `terraform validate` + `terraform plan` runs on every PR
- `terraform apply` is **intentional and manual only**
- Add secrets to GitHub → Settings → Secrets → Actions:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`

---

## How to Run

**1. Clone**
```bash
git clone https://github.com/Thiru-2004-varul/enterprise-idp-platform.git
cd enterprise-idp-platform
```

**2. Set credentials**
```bash
# .tfvars is gitignored — create it from the example
cp infrastructure/environments/dev/terraform.tfvars.example \
   infrastructure/environments/dev/terraform.tfvars

# Fill in values — already set for ap-south-1 dev
```

**3. Plan**
```bash
cd infrastructure/environments/dev
terraform init
terraform plan -var-file=terraform.tfvars
```

**4. Apply**
```bash
terraform apply -var-file=terraform.tfvars
# EKS takes 15–20 min · costs ~₹17/hr · destroy when done
```

**5. Connect**
```bash
aws eks update-kubeconfig --name dev-idp-cluster --region ap-south-1
kubectl get nodes
kubectl apply -f ../../k8s/namespaces/
kubectl apply -f ../../k8s/rbac/
kubectl get resourcequota -A
```

**6. Destroy**
```bash
terraform destroy -var-file=terraform.tfvars
```

---

## Author

**Thiruvarul G** — AWS DevOps Engineer · [github.com/Thiru-2004-varul](https://github.com/Thiru-2004-varul)
