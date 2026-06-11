output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.main.id
}

output "bastion_public_ip" {
  description = "IP publique du bastion (EIP)"
  value       = aws_eip.bastion.public_ip
}

output "bastion_public_dns" {
  description = "DNS public du bastion"
  value       = aws_eip.bastion.public_dns
}

output "ssh_bastion_command" {
  description = "Commande SSH pour se connecter au bastion avec agent forwarding"
  value       = "ssh -A ec2-user@${aws_eip.bastion.public_ip}"
}

output "web_private_ips" {
  description = "IPs privées des instances web (map az => ip)"
  value       = { for k, v in aws_instance.web : k => v.private_ip }
}

output "web_instance_ids" {
  description = "IDs des instances web (map az => instance_id)"
  value       = { for k, v in aws_instance.web : k => v.id }
}

output "nat_gateway_public_ip" {
  description = "IP publique de la NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "public_subnet_ids" {
  description = "Map AZ => subnet_id publics"
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  description = "Map AZ => subnet_id privés"
  value       = { for k, v in aws_subnet.private : k => v.id }
}
