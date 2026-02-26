variable "aws_region" {
  type = string
}

variable "environment" {
  type = string
}

variable "enable_creation" {
  type = bool
}

variable "public_subnet_count" {
  type = number
}

variable "private_subnet_count" {
  type = number
}
