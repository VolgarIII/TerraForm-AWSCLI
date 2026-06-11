variable "aws_region" {
  type        = string
  description = "Région AWS cible"
  default     = "eu-west-3"
}

variable "environment" {
  type        = string
  description = "Environnement (dev / staging / prod)"
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit être dev, staging ou prod."
  }
}

variable "project_name" {
  type        = string
  description = "Préfixe de nommage des ressources"
  default     = "formation"
}

variable "vpc_cidr" {
  type        = string
  description = "Bloc CIDR du VPC"
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr doit être un bloc CIDR valide."
  }
}

variable "azs" {
  type        = list(string)
  description = "Liste des zones de disponibilité (min 2)"
  default     = ["eu-west-3a", "eu-west-3b"]
  validation {
    condition     = length(var.azs) >= 2
    error_message = "Au moins 2 AZs sont requises."
  }
}

variable "bastion_allowed_cidr" {
  type        = string
  description = "CIDR autorisé pour SSH vers le bastion (votre IP publique /32)"
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  type        = string
  description = "Type d'instance EC2"
  default     = "t3.micro"
}

variable "public_key_path" {
  type        = string
  description = "Chemin vers la clé publique SSH à déposer sur les instances"
  default     = "~/.ssh/id_rsa.pub"
}
