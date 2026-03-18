output "vpc_id" {
  description = "VPC ID for this environment"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "alb_sg_id" {
  description = "ALB security group ID"
  value       = module.security.alb_sg_id
}

output "ec2_sg_id" {
  description = "EC2 security group ID"
  value       = module.security.ec2_sg_id
}

output "eks_cluster_name" {
  description = "EKS cluster name — use with: aws eks update-kubeconfig --name <value>"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}
