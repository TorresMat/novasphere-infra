output "alb_dns_name" {
  description = "Nom DNS public de l'ALB."
  value       = aws_lb.web.dns_name
}

output "target_group_arn" {
  description = "ARN du target group HTTP des instances Web."
  value       = aws_lb_target_group.web.arn
}

output "vpc_id" {
  description = "Identifiant du VPC de cet environnement."
  value       = module.vpc.vpc_id
}

output "autoscaling_group_name" {
  description = "Nom de l'Auto Scaling Group."
  value       = aws_autoscaling_group.web.name
}

output "ssm_parameter_name" {
  description = "Nom du paramètre SSM ; ne retourne jamais sa valeur."
  value       = aws_ssm_parameter.app_secret.name
}
