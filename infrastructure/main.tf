module "vpc" {
  source = "./modules/vpc"

  environment          = var.environment
  enable_creation      = var.enable_creation
  aws_region           = var.aws_region
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
}
