variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "enable_creation" {
  type    = bool
  default = false
}

variable "environment" {
  type    = string
  default = "dev"
}