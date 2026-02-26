output "vpc_id" {
  value = try(aws_vpc.this[0].id, null)
}

output "public_subnet_ids" {
  value = try(aws_subnet.public[*].id, [])
}

output "private_subnet_ids" {
  value = try(aws_subnet.private[*].id, [])
}
