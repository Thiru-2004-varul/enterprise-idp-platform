module "root" {
  source = "../../"

  aws_region      = var.aws_region
  enable_creation = var.enable_creation
  environment     = var.environment
}
