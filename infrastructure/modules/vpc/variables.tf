variable "environment" {
  type = string
}

variable "enable_creation" {
  type = bool
}

variable "aws_region" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_count" {
  type = number
}

variable "private_subnet_count" {
  type = number
}
