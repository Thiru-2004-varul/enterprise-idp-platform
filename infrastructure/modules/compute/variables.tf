variable "environment" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "ec2_sg_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}