aws_region   = "eu-west-3"
environment  = "dev"
project_name = "formation"
vpc_cidr     = "10.0.0.0/16"
azs          = ["eu-west-3a", "eu-west-3b"]

# Remplacez par votre IP publique pour restreindre l'accès SSH au bastion
# Exemple : bastion_allowed_cidr = "203.0.113.42/32"
bastion_allowed_cidr = "0.0.0.0/0"

instance_type   = "t3.micro"
public_key_path = "~/.ssh/id_rsa.pub"
