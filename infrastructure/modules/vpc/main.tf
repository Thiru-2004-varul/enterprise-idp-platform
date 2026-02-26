resource "aws_vpc" "this" {
  count = var.enable_creation ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "idp-${var.environment}-vpc"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}


resource "aws_subnet" "public" {
  count = var.enable_creation ? var.public_subnet_count : 0

  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = "${var.aws_region}${element(["a","b","c"], count.index)}"
  map_public_ip_on_launch = true

  tags = {
    Name        = "idp-${var.environment}-public-${count.index + 1}"
    Environment = var.environment
  }
}


resource "aws_subnet" "private" {
  count = var.enable_creation ? var.private_subnet_count : 0

  vpc_id            = aws_vpc.this[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = "${var.aws_region}${element(["a","b","c"], count.index)}"

  tags = {
    Name        = "idp-${var.environment}-private-${count.index + 1}"
    Environment = var.environment
  }
}
