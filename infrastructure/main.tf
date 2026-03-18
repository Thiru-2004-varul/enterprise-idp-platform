module "vpc" {
  source = "./modules/vpc"

  environment          = var.environment
  enable_creation      = var.enable_creation
  aws_region           = var.aws_region
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
}

module "security" {
  source      = "./modules/security"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
}

module "iam" {
  source      = "./modules/iam"
  environment = var.environment
}

module "eks" {
  source = "./modules/eks"

  environment             = var.environment
  private_subnet_ids      = module.vpc.private_subnet_ids
  eks_cluster_role_arn    = module.iam.eks_cluster_role_arn
  eks_node_group_role_arn = module.iam.eks_node_group_role_arn
  instance_type           = "t3.medium"
  desired_nodes           = 1
  min_nodes               = 1
  max_nodes               = 3
}
