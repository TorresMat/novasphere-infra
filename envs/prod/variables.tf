variable "owner" {
  description = "Trigramme de l'équipe, utilisé pour nommer et taguer les ressources."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{3}$", var.owner))
    error_message = "owner doit être composé de trois lettres minuscules."
  }
}

variable "aws_region" {
  description = "Région AWS imposée par le Learner Lab du cours."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "Le projet du cours doit être déployé en us-east-1."
  }
}

variable "instance_type" {
  description = "Type EC2 utilisé par le Launch Template."
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr" {
  description = "CIDR propre à cet environnement afin de garder dev et prod isolés."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr doit être un réseau CIDR valide."
  }
}

variable "use_lab_instance_profile" {
  description = "Utiliser le profil IAM préexistant AWS Academy au lieu de créer un rôle."
  type        = bool
  default     = true
}

variable "lab_instance_profile_name" {
  description = "Nom du profil IAM fourni par AWS Academy Learner Lab."
  type        = string
  default     = "LabInstanceProfile"
}

variable "app_secret" {
  description = "Secret applicatif transmis uniquement au paramètre SSM via son argument write-only."
  type        = string
  sensitive   = true
  ephemeral   = true

  validation {
    condition     = length(trimspace(var.app_secret)) >= 16
    error_message = "Le secret applicatif doit contenir au moins 16 caractères."
  }
}

variable "app_secret_version" {
  description = "Version entière à incrémenter lorsque le secret est renouvelé."
  type        = number
  default     = 1

  validation {
    condition     = var.app_secret_version >= 1 && var.app_secret_version == floor(var.app_secret_version)
    error_message = "app_secret_version doit être un entier positif."
  }
}
