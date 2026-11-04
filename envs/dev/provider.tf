locals {
  environment = "dev"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "NovaSphere"
      Environment = local.environment
      Owner       = var.owner
      ManagedBy   = "Terraform"
    }
  }
}
