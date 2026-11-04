resource "aws_ssm_parameter" "app_secret" {
  name        = "/novasphere/${var.environment}/${var.owner}/app-secret"
  description = "Secret applicatif NovaSphere ${var.environment} ; valeur write-only."
  type        = "SecureString"
  tier        = "Standard"

  # value_wo est write-only : Terraform ne stocke jamais la valeur dans le state.
  value_wo         = var.app_secret
  value_wo_version = var.app_secret_version

  tags = {
    Name        = "${local.name_prefix}-app-secret"
    Environment = var.environment
  }
}
