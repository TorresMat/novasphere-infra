variable "owner" {
  description = "Trigramme de l'équipe."
  type        = string
}

variable "environment" {
  description = "Environnement déployé par le module partagé."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment doit être dev ou prod."
  }
}

variable "aws_region" {
  description = "Région AWS utilisée pour le paramètre SSM et les ressources régionales."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR du VPC propre à l'environnement."
  type        = string
}

variable "instance_type" {
  description = "Type EC2 du Launch Template."
  type        = string
}

variable "use_lab_instance_profile" {
  description = "Utilise le profil IAM préexistant du Learner Lab."
  type        = bool
}

variable "lab_instance_profile_name" {
  description = "Nom du profil d'instance fourni par AWS Academy."
  type        = string
}

variable "app_secret" {
  description = "Secret applicatif éphémère ; transmis au paramètre SSM via value_wo."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "app_secret_version" {
  description = "Version d'écriture du secret SSM, incrémentée à chaque rotation."
  type        = number
}
