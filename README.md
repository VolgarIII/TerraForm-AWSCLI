# TP01 — Bucket S3 sécurisé

> Dépôt : https://github.com/VolgarIII/TerraForm-AWSCLI.git

Provisionnement d'un bucket S3 production-ready avec Terraform.

## Prérequis

- Terraform >= 1.7.0 (via tfenv)
- AWS CLI v2 + profil `formation` configuré
- TFLint >= 0.50.0

## Ressources créées

| Ressource | Description |
|---|---|
| `aws_s3_bucket` | Bucket S3 avec nom unique |
| `aws_s3_bucket_versioning` | Versioning activé |
| `aws_s3_bucket_server_side_encryption_configuration` | Chiffrement AES256 |
| `aws_s3_bucket_public_access_block` | Blocage total des accès publics |
| `aws_s3_bucket_policy` | Refus des requêtes HTTP (TLS obligatoire) |

## Utilisation

```bash
export AWS_PROFILE=formation

terraform init
terraform plan
terraform apply
```

Renseigner la variable `owner` (email) dans `terraform.tfvars` :

```hcl
owner = "votre-email@example.com"
```

## Variables

| Variable | Type | Défaut | Description |
|---|---|---|---|
| `bucket_prefix` | string | `formation-tp01` | Préfixe du nom du bucket |
| `environment` | string | `dev` | Environnement (`dev`, `staging`, `prod`) |
| `owner` | string | — | Email de l'owner (obligatoire) |

## Outputs

| Output | Description |
|---|---|
| `bucket_name` | Nom du bucket créé |
| `bucket_arn` | ARN complet du bucket |
| `bucket_region` | Région AWS |
| `versioning_status` | Statut du versioning |

## Nettoyage

```bash
terraform destroy
```
