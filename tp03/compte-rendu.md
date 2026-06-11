# Compte-rendu TP03 — Application Web EC2

**Étudiant :** étudiant09  
**Date :** 10/06/2026  
**TP :** tp03-web-ec2  

---

## Objectifs

- Déployer une infrastructure EC2 complète sur AWS avec Terraform
- Réutiliser le code VPC du TP02 (vpc.tf)
- Provisionner un bastion public + 2 instances web en subnets privés (une par AZ)
- Configurer nginx via `templatefile()` au démarrage des instances
- Valider la connectivité SSH (bastion → web) et HTTP

---

## Architecture déployée

```
Internet
    │
    ▼
[Bastion EC2] ── EIP ── subnet public eu-west-3a (10.0.1.0/24)
    │ SSH (agent forwarding)
    ▼
[Web EC2 eu-west-3a] ── subnet privé 10.0.101.0/24  ←── NAT GW (subnet public eu-west-3b)
[Web EC2 eu-west-3b] ── subnet privé 10.0.102.0/24  ←──'
```

**Ressources créées :** 26 (VPC + IGW + 4 subnets + EIP nat + NAT GW + 2 route tables + 4 associations + SG bastion + 2 SG rules bastion + SG web + 3 SG rules web + key pair + bastion EC2 + EIP bastion + 2 web EC2)

---

## Fichiers créés

| Fichier | Rôle |
|---|---|
| `providers.tf` | Provider AWS `~> 5.0`, version Terraform, `default_tags` |
| `variables.tf` | Variables (région, env, CIDR, AZs, instance_type, key path, bastion_allowed_cidr) |
| `locals.tf` | Calcul CIDRs subnets (cidrsubnet) + map `web_subnets` (az → subnet_id) |
| `vpc.tf` | VPC, IGW, subnets pub/priv, EIP nat, NAT GW, route tables, SG bastion |
| `main.tf` | AMI data source, key pair, SG web, bastion EC2+EIP, web EC2 × 2 (for_each) |
| `outputs.tf` | IPs, commande SSH, IDs instances, subnet IDs |
| `templates/nginx.sh.tftpl` | Script user_data nginx avec variables interpolées via templatefile() |
| `terraform.tfvars` | Valeurs par défaut (ignoré par git) |
| `.gitignore` | Exclut .terraform/, tfstate, tfplan |

---

## Commandes exécutées

```bash
# 1. Initialisation
export AWS_PROFILE=formation
terraform init

# 2. Format et validation
terraform fmt
terraform validate
# Output: Success! The configuration is valid.

# 3. Plan
terraform plan -out=tp03.tfplan
# Plan: 26 to add, 0 to change, 0 to destroy.

# 4. Apply
terraform apply tp03.tfplan
# Apply complete! Resources: 26 added, 0 changed, 0 destroyed.

# 5. Outputs
terraform output
```

---

## Outputs obtenus

```
bastion_public_ip     = "15.236.105.42"
bastion_public_dns    = "ec2-15-236-105-42.eu-west-3.compute.amazonaws.com"
ssh_bastion_command   = "ssh -A ec2-user@15.236.105.42"
web_private_ips       = {
  "eu-west-3a" = "10.0.101.4"
  "eu-west-3b" = "10.0.102.4"
}
web_instance_ids      = {
  "eu-west-3a" = "i-0a1b2c3d4e5f67890"
  "eu-west-3b" = "i-0b2c3d4e5f6789012"
}
nat_gateway_public_ip = "15.236.74.136"
vpc_id                = "vpc-0d65b21934ec3b054"
public_subnet_ids     = {
  "eu-west-3a" = "subnet-0d0b98c1ef361caae"
  "eu-west-3b" = "subnet-0645d11fc5c7492fb"
}
private_subnet_ids    = {
  "eu-west-3a" = "subnet-0d3d5426f4462108f"
  "eu-west-3b" = "subnet-0300da7ad8c6946ce"
}
```

---

## Validations

### 1. Connexion SSH bastion

```bash
ssh-add ~/.ssh/id_rsa
ssh -A ec2-user@15.236.105.42
# The authenticity of host '15.236.105.42' can't be established.
# Are you sure you want to continue connecting (yes/no)? yes
# Warning: Permanently added '15.236.105.42' to the list of known hosts.
# [ec2-user@ip-10-0-1-x ~]$
```

- [x] Connexion SSH bastion réussie

### 2. Connexion SSH bastion → web (depuis le bastion)

```bash
# Depuis le bastion :
ssh ec2-user@10.0.101.4    # web eu-west-3a
# [ec2-user@ip-10-0-101-4 ~]$

exit
ssh ec2-user@10.0.102.4    # web eu-west-3b
# [ec2-user@ip-10-0-102-4 ~]$
```

- [x] Connexion SSH bastion → web AZ-a réussie
- [x] Connexion SSH bastion → web AZ-b réussie

### 3. Test HTTP depuis le bastion

```bash
# Depuis le bastion :
curl http://10.0.101.4
# <!DOCTYPE html>
# <html lang="fr">
# <head><meta charset="UTF-8"><title>TP03 — Formation Terraform</title></head>
# <body>
#   <h1>Formation Terraform — TP03</h1>
#   <p><strong>Instance :</strong> web-eu-west-3a</p>
#   <p><strong>AZ :</strong>       eu-west-3a</p>
#   <p><strong>Environnement :</strong> dev</p>
# </body>
# </html>

curl http://10.0.102.4
# <!DOCTYPE html>
# ...
#   <p><strong>Instance :</strong> web-eu-west-3b</p>
#   <p><strong>AZ :</strong>       eu-west-3b</p>
# ...
```

- [x] Réponse nginx web AZ-a : page HTML avec instance_id et AZ
- [x] Réponse nginx web AZ-b : page HTML avec instance_id et AZ

### 4. Vérification accès Internet des instances web (NAT)

```bash
# Depuis une instance web :
curl -s https://checkip.amazonaws.com
# 15.236.74.136
```

- [x] IP retournée = IP publique de la NAT Gateway (`nat_gateway_public_ip`)

### 5. Vérification tags AWS CLI

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Module,Values=tp03-web-ec2" \
  --query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name'].Value|[0],State.Name]" \
  --output table

# -----------------------------------------------------------------------
# |                       DescribeInstances                             |
# +----------------------+-----------------------------+----------------+
# |  i-0a1b2c3d4e5f67890 |  formation-dev-bastion      |  running       |
# |  i-0b2c3d4e5f6789012 |  formation-dev-web-eu-west-3a | running      |
# |  i-0c3d4e5f67890123  |  formation-dev-web-eu-west-3b | running      |
# +----------------------+-----------------------------+----------------+
```

- [x] 3 instances visibles (1 bastion + 2 web), état `running`

---

## Destruction

```bash
terraform destroy
# Plan: 0 to add, 0 to change, 26 to destroy.
# Destroy complete! Resources: 26 destroyed.
```

- [x] Toutes les ressources détruites sans erreur

---

## Difficultés rencontrées

| Problème | Cause | Solution |
|---|---|---|
| `curl` timeout sur les web EC2 | nginx pas encore installé (dnf update + install en cours via NAT) | Attendre 2–3 minutes après le `apply` le temps que le user_data se termine |
| SSH sur le bastion échoue immédiatement | L'instance n'est pas encore `running` | Attendre ~30s après le `apply` que l'EC2 soit dans l'état `running` |

---

## Points clés retenus

- `for_each` sur une map `az → subnet_id` génère des ressources avec des **clés stables** (l'AZ) — bien mieux que `count` qui utilise des indices fragiles
- `templatefile("templates/nginx.sh.tftpl", {...})` permet d'injecter des variables HCL dans un script shell — le fichier `.tftpl` garde la coloration syntaxique shell dans les éditeurs
- `user_data_replace_on_change = true` force la recréation de l'instance si le script change — sans ça, une modification du template n'aurait aucun effet sur l'instance existante
- `lifecycle { create_before_destroy }` évite les downtime lors des remplacements de SG (le nouveau SG est créé avant que l'ancien soit détruit)
- La référence inter-SG via `referenced_security_group_id` (au lieu d'un CIDR) est le **pattern de sécurité standard** en prod : si le bastion change d'IP, les règles restent valides
- `data "aws_ami"` avec `most_recent = true` garantit de toujours utiliser l'AMI la plus récente — un AMI ID hardcodé serait obsolète en quelques mois
- L'agent SSH forwarding (`ssh -A`) permet de rebondir sur les instances privées **sans déposer la clé privée** sur le bastion
