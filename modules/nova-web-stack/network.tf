data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = local.name_prefix
  cidr = var.vpc_cidr

  azs                           = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets                = local.public_subnets
  create_igw                    = true
  enable_dns_hostnames          = true
  enable_dns_support            = true
  enable_nat_gateway            = false
  single_nat_gateway            = false
  map_public_ip_on_launch       = true
  manage_default_network_acl    = true
  manage_default_route_table    = true
  manage_default_security_group = true

  public_subnet_tags = {
    Tier = "public"
  }

  tags = {
    Project     = "NovaSphere"
    Environment = var.environment
    Owner       = var.owner
  }
}
