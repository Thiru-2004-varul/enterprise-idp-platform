variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
}

variable "environment" {
  type        = string
  description = "Deployment environment name"
}

variable "enable_creation" {
  type        = bool
  description = "Set to true to actually create resources"
}

variable "public_subnet_count" {
  type        = number
  description = "Number of public subnets to create"
}

variable "private_subnet_count" {
  type        = number
  description = "Number of private subnets to create"
}
