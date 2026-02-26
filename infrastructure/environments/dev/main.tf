

module "root" {
  source = "../../"

  aws_region           = var.aws_region
  environment          = var.environment
  enable_creation      = var.enable_creation
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
}
