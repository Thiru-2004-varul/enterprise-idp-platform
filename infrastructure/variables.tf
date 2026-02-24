variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "ap-south-1"
}

variable "enable_creation" {
  description = "Toggle actual infrastructure provisioning"
  type        = bool
  default     = false
}