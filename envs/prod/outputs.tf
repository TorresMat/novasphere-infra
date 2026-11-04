output "alb_dns_name" {
  description = "Nom DNS public de l'Application Load Balancer."
  value       = module.nova_web_stack.alb_dns_name
}

output "alb_url" {
  description = "URL HTTP de l'application NovaSphere."
  value       = "http://${module.nova_web_stack.alb_dns_name}"
}

output "vpc_id" {
  description = "Identifiant du VPC isolé de cet environnement."
  value       = module.nova_web_stack.vpc_id
}

output "autoscaling_group_name" {
  description = "Nom du groupe Auto Scaling."
  value       = module.nova_web_stack.autoscaling_group_name
}

output "ssm_parameter_name" {
  description = "Nom du paramètre applicatif ; sa valeur n'est jamais exposée."
  value       = module.nova_web_stack.ssm_parameter_name
}
