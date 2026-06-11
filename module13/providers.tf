terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
  default_tags {
    tags = {
      Project     = "formation-terraform"
      Module      = "module13-security-groups"
      ManagedBy   = "Terraform"
      Environment = "dev"
      Owner       = "etudiant09"
    }
  }
}
