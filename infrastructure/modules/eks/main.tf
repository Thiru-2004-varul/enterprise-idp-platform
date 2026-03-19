resource "aws_eks_cluster" "this" {
  count    = length(var.private_subnet_ids) > 0 ? 1 : 0
  name     = "${var.environment}-idp-cluster"
  role_arn = var.eks_cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  tags = {
    Name        = "${var.environment}-idp-cluster"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_eks_node_group" "this" {
  count           = length(var.private_subnet_ids) > 0 ? 1 : 0
  cluster_name    = aws_eks_cluster.this[0].name
  node_group_name = "${var.environment}-node-group"
  node_role_arn   = var.eks_node_group_role_arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = var.desired_nodes
    min_size     = var.min_nodes
    max_size     = var.max_nodes
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Name        = "${var.environment}-node-group"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  depends_on = [aws_eks_cluster.this]
}
