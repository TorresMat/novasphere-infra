# Le tag v2.0.2 utilise une liste de SG sources, compatible avec les IDs connus seulement après création.
module "sg_alb" {
  source = "git::https://github.com/RaiZing955/terraform-aws-web-sg.git?ref=v2.0.4"

  name          = "${local.name_prefix}-alb"
  vpc_id        = module.vpc.vpc_id
  ingress_port  = 80
  allowed_cidrs = ["0.0.0.0/0"]
  egress_ports  = [80]

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}

module "sg_web" {
  source = "git::https://github.com/RaiZing955/terraform-aws-web-sg.git?ref=v2.0.4"

  name                      = "${local.name_prefix}-web"
  vpc_id                    = module.vpc.vpc_id
  ingress_port              = 80
  allowed_cidrs             = []
  source_security_group_ids = [module.sg_alb.security_group_id]
  egress_ports              = [80, 443]

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}
