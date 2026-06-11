output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID du VPC"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "CIDR du VPC"
}

output "public_subnet_ids" {
  value       = { for k, s in aws_subnet.public : k => s.id }
  description = "Map AZ -> ID de subnet public"
}

output "private_subnet_ids" {
  value       = { for k, s in aws_subnet.private : k => s.id }
  description = "Map AZ -> ID de subnet prive"
}

output "nat_gateway_public_ip" {
  value       = aws_eip.nat.public_ip
  description = "IP publique du NAT Gateway"
}

output "bastion_security_group_id" {
  value       = aws_security_group.formation_bastion_sg.id
  description = "ID du Security Group bastion"
}
