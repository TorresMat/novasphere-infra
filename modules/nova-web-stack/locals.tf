locals {
  name_prefix = "novasphere-${var.environment}-${var.owner}"

  public_subnets = [
    cidrsubnet(var.vpc_cidr, 8, 1),
    cidrsubnet(var.vpc_cidr, 8, 2),
  ]

  instance_profile_name = var.use_lab_instance_profile ? var.lab_instance_profile_name : aws_iam_instance_profile.web[0].name
}
