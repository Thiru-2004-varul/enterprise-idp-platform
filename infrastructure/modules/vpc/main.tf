resource "aws_vpc" "this" {
  count                = var.enable_creation ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "idp-${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count                   = var.enable_creation ? var.public_subnet_count : 0
  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = "${var.aws_region}${element(["a", "b", "c"], count.index)}"
  map_public_ip_on_launch = true
  tags = {
    Name                     = "idp-${var.environment}-public-${count.index + 1}"
    Environment              = var.environment
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private" {
  count             = var.enable_creation ? var.private_subnet_count : 0
  vpc_id            = aws_vpc.this[0].id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = "${var.aws_region}${element(["a", "b", "c"], count.index)}"
  tags = {
    Name                              = "idp-${var.environment}-private-${count.index + 1}"
    Environment                       = var.environment
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_internet_gateway" "this" {
  count  = var.enable_creation ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  tags = {
    Name = "idp-${var.environment}-igw"
  }
}

resource "aws_route_table" "public" {
  count  = var.enable_creation ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  tags = {
    Name = "idp-${var.environment}-public-rt"
  }
}

resource "aws_route" "public_internet_access" {
  count                  = var.enable_creation ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  count          = var.enable_creation ? var.public_subnet_count : 0
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_eip" "nat" {
  count  = var.enable_creation ? 1 : 0
  domain = "vpc"
  tags = {
    Name = "idp-${var.environment}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  count         = var.enable_creation ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.this]
  tags = {
    Name = "idp-${var.environment}-nat"
  }
}

resource "aws_route_table" "private" {
  count  = var.enable_creation ? 1 : 0
  vpc_id = aws_vpc.this[0].id
  tags = {
    Name = "idp-${var.environment}-private-rt"
  }
}

resource "aws_route" "private_nat_access" {
  count                  = var.enable_creation ? 1 : 0
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count          = var.enable_creation ? var.private_subnet_count : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}
