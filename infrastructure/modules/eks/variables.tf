variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for EKS nodes"
}

variable "eks_cluster_role_arn" {
  type        = string
  description = "ARN of the IAM role for the EKS control plane"
}

variable "eks_node_group_role_arn" {
  type        = string
  description = "ARN of the IAM role for EKS worker nodes"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.29"
  description = "Kubernetes version for the EKS cluster"
}

variable "instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance type for worker nodes"
}

variable "desired_nodes" {
  type        = number
  default     = 1
  description = "Desired number of worker nodes"
}

variable "min_nodes" {
  type        = number
  default     = 1
  description = "Minimum worker nodes"
}

variable "max_nodes" {
  type        = number
  default     = 3
  description = "Maximum worker nodes"
}
