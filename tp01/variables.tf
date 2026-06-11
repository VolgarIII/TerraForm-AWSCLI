variable "project" {
  type        = string
  description = "Nom du projet, utilise comme prefixe du bucket"
  default     = "formation-tp01"
}

variable "tags" {
  type        = map(string)
  description = "Tags supplementaires a appliquer aux ressources"
  default     = {}
}

variable "environment" {
  type        = string
  description = "Environnement de deploiement"
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment doit etre dev, staging ou prod."
  }
}

variable "owner" {
  type        = string
  description = "Email de l'owner du bucket"
  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+$", var.owner))
    error_message = "owner doit etre un email valide."
  }
}
