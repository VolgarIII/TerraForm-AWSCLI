variable "bucket_prefix" {
  type        = string
  description = "Prefixe applique au nom du bucket S3"
  default     = "formation-tp01"
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
