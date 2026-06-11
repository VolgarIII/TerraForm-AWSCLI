# Compte-rendu TP03 — Application Web EC2

**Étudiant :** étudiant09  
**Date :** 11/06/2026  
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
[Bastion EC2] ── EIP 13.39.61.15 ── subnet public eu-west-3a (10.0.1.0/24)
    │ SSH (agent forwarding)
    ▼
[Web EC2 eu-west-3a] ── subnet privé 10.0.101.0/24  ←── NAT GW 15.236.74.136
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
bastion_public_ip     = "13.39.61.15"
bastion_public_dns    = "ec2-13-39-61-15.eu-west-3.compute.amazonaws.com"
ssh_bastion_command   = "ssh -A ec2-user@13.39.61.15"
web_private_ips       = {
  "eu-west-3a" = "10.0.101.220"
  "eu-west-3b" = "10.0.102.246"
}
web_instance_ids      = {
  "eu-west-3a" = "i-08486c28b56304163"
  "eu-west-3b" = "i-0258469b5dbad71b5"
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
ssh -A ec2-user@13.39.61.15
# Warning: Permanently added '13.39.61.15' (ED25519) to the list of known hosts.
#    ,     #_
#    ~\_  ####_        Amazon Linux 2023
#   ~~  \_#####\
#   ~~     \###|
#   ~~       \#/ ___   https://aws.amazon.com/linux/amazon-linux-2023
# [ec2-user@ip-10-0-1-6 ~]$
```

- [x] Connexion SSH bastion réussie

### 2. Connexion SSH bastion → web (depuis le bastion)

```bash
ssh ec2-user@10.0.101.220   # web eu-west-3a
# [ec2-user@ip-10-0-101-220 ~]$

ssh ec2-user@10.0.102.246   # web eu-west-3b
# [ec2-user@ip-10-0-102-246 ~]$
```

- [x] Connexion SSH bastion → web AZ-a réussie
- [x] Connexion SSH bastion → web AZ-b réussie

### 3. Test HTTP depuis le bastion

```bash
curl http://10.0.101.220
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

curl http://10.0.102.246
#   <p><strong>Instance :</strong> web-eu-west-3b</p>
#   <p><strong>AZ :</strong>       eu-west-3b</p>
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

# +----------------------+--------------------------------+---------+
# |  i-00326d2964d36de5f |  formation-dev-bastion         | running |
# |  i-08486c28b56304163 |  formation-dev-web-eu-west-3a  | running |
# |  i-0258469b5dbad71b5 |  formation-dev-web-eu-west-3b  | running |
# +----------------------+--------------------------------+---------+
```

- [x] 3 instances visibles (1 bastion + 2 web), état `running`

---

## Destruction

```bash
terraform destroy
# Plan: 0 to add, 0 to change, 26 to destroy.
# Destroy complete! Resources: 26 destroyed.
```

- [ ] Toutes les ressources détruites sans erreur *(à faire après validation)*

---

## Difficultés rencontrées

| Problème | Cause | Solution |
|---|---|---|
| `tfenv: Version could not be resolved` | tfenv installé mais aucune version définie | `tfenv install 1.9.8 && tfenv use 1.9.8` |
| `No valid credential sources found` | `AWS_PROFILE` non défini dans la session WSL | `export AWS_PROFILE=formation` avant chaque session |
| `InvalidKeyPair.Duplicate` | Clé SSH `formation-dev-key` déjà présente dans AWS depuis un précédent TP, et clé locale différente | `aws ec2 delete-key-pair --key-name formation-dev-key --region eu-west-3` puis `terraform plan/apply` |
| `Saved plan is stale` | Le state AWS a changé (suppression key pair) après le plan | Relancer `terraform plan -out=tp03.tfplan` puis `terraform apply` |
| `curl` timeout sur les web EC2 | nginx pas encore installé (dnf update + install en cours via NAT) | Attendre 2–3 minutes après le `apply` |

---

## Points clés retenus

- `for_each` sur une map `az → subnet_id` génère des ressources avec des **clés stables** (l'AZ) — bien mieux que `count` qui utilise des indices fragiles
- `templatefile("templates/nginx.sh.tftpl", {...})` permet d'injecter des variables HCL dans un script shell
- `user_data_replace_on_change = true` force la recréation de l'instance si le script change
- `lifecycle { create_before_destroy }` évite les downtime lors des remplacements de SG
- La référence inter-SG via `referenced_security_group_id` est le **pattern de sécurité standard** en prod
- `data "aws_ami"` avec `most_recent = true` garantit de toujours utiliser l'AMI la plus récente
- L'agent SSH forwarding (`ssh -A`) permet de rebondir sur les instances privées **sans déposer la clé privée** sur le bastion
- Toujours faire `export AWS_PROFILE=formation` avant les commandes Terraform/AWS CLI en WSL
