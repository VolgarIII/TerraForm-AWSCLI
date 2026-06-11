# Compte rendu — TP02 : Infrastructure VPC complète

## Informations générales

| Champ | Valeur |
|---|---|
| TP | 02 — VPC complet 2 AZ |
| Durée | 1h30 |
| Date | 10/06/2026 |
| Étudiant | Julien |

---

## Objectif

Coder from scratch un VPC AWS complet à 2 AZ : VPC, subnets publics/privés, IGW, NAT Gateway, route tables, security group bastion SSH.

---

## Architecture

```
Internet → IGW → Route Table publique
                      ↓
         subnet public AZ-a    subnet public AZ-b
              ↓ NAT
         Route Table privée
                      ↓
         subnet privé AZ-a     subnet privé AZ-b
```

| Ressource | CIDR / Détail |
|---|---|
| VPC | 10.0.0.0/16 |
| Subnet public AZ-a | 10.0.1.0/24 |
| Subnet public AZ-b | 10.0.2.0/24 |
| Subnet privé AZ-a | 10.0.101.0/24 |
| Subnet privé AZ-b | 10.0.102.0/24 |

---

## Ressources créées (17 au total)

| Ressource | Quantité |
|---|---|
| `aws_vpc` | 1 |
| `aws_internet_gateway` | 1 |
| `aws_subnet.public` | 2 (for_each) |
| `aws_subnet.private` | 2 (for_each) |
| `aws_eip` | 1 |
| `aws_nat_gateway` | 1 |
| `aws_route_table` | 2 |
| `aws_route_table_association` | 4 (for_each) |
| `aws_security_group` | 1 |
| `aws_vpc_security_group_ingress_rule` | 1 |
| `aws_vpc_security_group_egress_rule` | 1 |

---

## Étapes réalisées

### Étape 1 — Structure du projet ✅

Création du dossier `tp02/` avec tous les fichiers nécessaires.

### Étape 2 — providers.tf ✅

Provider AWS `~> 5.0`, région `eu-west-3`, `default_tags` avec `Environment = var.environment`.

### Étape 3 — variables.tf ✅

6 variables : `aws_region`, `environment` (validé), `project_name`, `vpc_cidr` (validé), `azs` (min 2), `bastion_allowed_cidr`.

### Étape 4 — locals.tf ✅

`name_prefix`, `public_subnets` et `private_subnets` calculés dynamiquement avec `cidrsubnet()`.

### Étapes 5 à 10 — main.tf ✅

VPC, IGW, subnets publics/privés (for_each), EIP, NAT Gateway, route tables, associations, Security Group bastion.

### Étape 11 — outputs.tf ✅

6 outputs : `vpc_id`, `vpc_cidr`, `public_subnet_ids`, `private_subnet_ids`, `nat_gateway_public_ip`, `bastion_security_group_id`.

### Étape 12 — Init, plan, apply ✅

```bash
export AWS_PROFILE=formation
terraform init      # hashicorp/aws v5.100.0 installé
terraform fmt       # aucun changement
terraform validate  # Success!
terraform plan      # Plan: 17 to add, 0 to change, 0 to destroy
terraform apply     # Apply complete! Resources: 4 added, 0 changed, 1 destroyed (reprise après interruption)
```

**Outputs après apply :**
```
bastion_security_group_id = "sg-0538761e54fe5889e"
nat_gateway_public_ip     = "13.39.138.185"
private_subnet_ids = {
  "eu-west-3a" = "subnet-0b6b76059491eca33"
  "eu-west-3b" = "subnet-0c225282a5c1a8a38"
}
public_subnet_ids = {
  "eu-west-3a" = "subnet-0f66e8052e19a2d22"
  "eu-west-3b" = "subnet-0e7d1e8f1d8909bfe"
}
vpc_cidr = "10.0.0.0/16"
vpc_id   = "vpc-01be74191e16e238e"
```

### Étape 13 — Validation manuelle

*À faire*

```bash
VPC_ID=$(terraform output -raw vpc_id)

aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --query Vpcs[0].CidrBlock
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
  --query Subnets[].[SubnetId, AvailabilityZone, CidrBlock, Tags[?Key==\`Tier\`].Value|[0]] \
  --output table
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID"
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" \
  --query NatGateways[0].[NatGatewayId, State, NatGatewayAddresses[0].PublicIp]
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID"
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=*bastion*"
```

| Critère | Résultat |
|---|---|
| VPC 10.0.0.0/16 | ✅ `vpc-01be74191e16e238e` |
| 2 subnets publics dans 2 AZ | ✅ `subnet-0f66e8052e19a2d22` / `subnet-0e7d1e8f1d8909bfe` |
| 2 subnets privés dans 2 AZ | ✅ `subnet-0b6b76059491eca33` / `subnet-0c225282a5c1a8a38` |
| IGW attaché | ✅ `igw-0c726cc8c8f161575` |
| NAT Gateway actif (eu-west-3b) | ✅ `nat-08650e269a2cb9db0` — IP `13.39.138.185` |
| Route table publique → IGW | ✅ `rtb-0e8e8c61fc7044bfe` |
| Route table privée → NAT | ✅ `rtb-0d419e42abbe791c0` |
| Security Group SSH bastion | ✅ `sg-0538761e54fe5889e` |
| `cidrsubnet()` utilisé | ✅ |
| `for_each` utilisé | ✅ |

### Étape 15 — Destroy et commit

```bash
terraform destroy
git add tp02/
git commit -m "tp02: VPC complet 2 AZ avec NAT, SG bastion (custom)"
git push
```

---

## Difficultés rencontrées

| Problème | Cause | Solution |
|---|---|---|
| | | |

---

## Points clés retenus

- `for_each` sur une map `AZ → CIDR` crée une ressource par entrée avec une clé stable
- `cidrsubnet(vpc_cidr, 8, idx+1)` génère des /24 depuis un /16
- Le NAT Gateway **doit être dans un subnet public**, pas privé
- `depends_on = [aws_internet_gateway.main]` obligatoire sur le NAT Gateway
- `aws_vpc_security_group_ingress_rule` (ressource séparée) au lieu des blocs `ingress {}` (provider AWS v5+)
- NAT Gateway = ~35€/mois → **toujours destroy à la fin du TP**
