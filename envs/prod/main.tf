module "nova_web_stack" {
  source                    = "../../modules/nova-web-stack"
  owner                     = var.owner
  environment               = local.environment
  aws_region                = var.aws_region
  vpc_cidr                  = var.vpc_cidr
  instance_type             = var.instance_type
  use_lab_instance_profile  = var.use_lab_instance_profile
  lab_instance_profile_name = var.lab_instance_profile_name
  app_secret                = var.app_secret
  app_secret_version        = var.app_secret_version
}
