output "cluster_name" {
  description = "EKS cluster name"
  value       = length(aws_eks_cluster.this) > 0 ? aws_eks_cluster.this[0].name : ""
}

output "cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = length(aws_eks_cluster.this) > 0 ? aws_eks_cluster.this[0].endpoint : ""
}

output "cluster_ca_certificate" {
  description = "Base64 cluster CA certificate"
  value       = length(aws_eks_cluster.this) > 0 ? aws_eks_cluster.this[0].certificate_authority[0].data : ""
  sensitive   = true
}
