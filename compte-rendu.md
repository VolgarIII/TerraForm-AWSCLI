# Compte rendu — TP01 : Bucket S3 sécurisé

## Informations générales

| Champ | Valeur |
|---|---|
| TP | 01 — Bucket S3 sécurisé |
| Durée | 1h30 |
| Date | 09/06/2026 |
| Étudiant | étudiant09 |
| Prérequis | Module 05 terminé ✅ |

---

## Objectif

Provisionner un bucket S3 production-ready avec toutes les bonnes pratiques de sécurité AWS : versioning, chiffrement SSE-S3, blocage des accès publics, politique TLS obligatoire, tags normalisés, et validation via TFLint.

---

## Structure du projet

```
tp01-s3-secure/
├── providers.tf       # Config Terraform + providers AWS & random + default_tags
├── variables.tf       # bucket_prefix, environment (validé), owner (email validé)
├── main.tf            # Bucket S3 + versioning + chiffrement + public access block + policy TLS
├── outputs.tf         # bucket_name, bucket_arn, bucket_region, versioning_status
├── terraform.tfvars   # Valeurs des variables (ignoré par git)
├── .tflint.hcl        # Config TFLint + plugin AWS
└── .gitignore
```

---

## Ressources Terraform créées

| Ressource | Rôle |
|---|---|
| `random_pet.suffix` | Suffixe unique pour le nom du bucket |
| `aws_s3_bucket.main` | Bucket S3 principal |
| `aws_s3_bucket_versioning.main` | Versioning activé |
| `aws_s3_bucket_server_side_encryption_configuration.main` | Chiffrement AES256 |
| `aws_s3_bucket_public_access_block.main` | Blocage accès publics (4 options) |
| `aws_s3_bucket_policy.main` | Policy : refus des requêtes HTTP |

---

## Étapes réalisées

### Étape 1 — Setup du projet ✅

Création du dossier `tp01-s3-secure/` avec tous les fichiers nécessaires.

```bash
tflint --init
```

**Résultat :** plugin AWS installé sans erreur.

### Étape 2 — providers.tf ✅

Provider AWS `~> 5.0` et random `~> 3.6`. `default_tags` incluant `Project`, `ManagedBy`, `CostCenter`, `Environment`.

### Étape 3 — variables.tf ✅

- `bucket_prefix` : string, default `"formation-tp01"`
- `environment` : string validé (`dev` / `staging` / `prod`)
- `owner` : email obligatoire, validé par regex

### Étape 4 — Bucket S3 de base ✅

Nom construit via `locals` : `${var.bucket_prefix}-${account_id}-${random_pet}`.

### Étape 5 — Versioning ✅

`aws_s3_bucket_versioning` avec `status = "Enabled"`.

### Étape 6 — Chiffrement SSE-S3 ✅

`aws_s3_bucket_server_side_encryption_configuration` avec `sse_algorithm = "AES256"`.

### Étape 7 — Block Public Access ✅

4 options à `true` : `block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`.

### Étape 8 — Bucket Policy (refus HTTP) ✅

`aws_iam_policy_document` avec `Deny` sur `aws:SecureTransport = false`. `depends_on` sur le public access block pour garantir l'ordre d'application.

### Étape 9 — outputs.tf ✅

4 outputs : `bucket_name`, `bucket_arn`, `bucket_region`, `versioning_status`.

### Étape 10 — Lint, plan, apply ✅

```bash
export AWS_PROFILE=formation
terraform init
terraform fmt
terraform validate
tflint
terraform plan   # Plan: 6 to add, 0 to change, 0 to destroy
terraform apply
```

**Résultat :**
```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:
bucket_arn    = "arn:aws:s3:::formation-tp01-039497794217-better-adder"
bucket_name   = "formation-tp01-039497794217-better-adder"
bucket_region = "eu-west-3"
versioning_status = "Enabled"
```

### Étape 11 — Validation manuelle ✅

```bash
BUCKET=$(terraform output -raw bucket_name)
# formation-tp01-039497794217-better-adder
```

| Vérification | Résultat |
|---|---|
| Bucket créé | ✅ `BucketRegion: eu-west-3` |
| Versioning `Enabled` | ✅ `"Status": "Enabled"` |
| Chiffrement `AES256` | ✅ `"SSEAlgorithm": "AES256"` |
| Block Public Access (4x `true`) | ✅ Les 4 options à `true` |
| Bucket policy (Deny HTTP) | ✅ `DenyInsecureTransport` sur `aws:SecureTransport: false` |
| Tags présents | ✅ `Project`, `Owner`, `ManagedBy`, `CostCenter`, `Environment` |
| TFLint exit 0 | ✅ |

### Étape 12 — Destroy et commit ✅

```bash
terraform destroy   # Destroy complete! Resources: 6 destroyed.
git init
git add .
git commit -m "tp01: bucket S3 securise (versioning, SSE, block public, TLS)"
```

---

## Difficultés rencontrées

| Problème | Cause | Solution |
|---|---|---|
| | | |

---

## Points clés retenus

- Les attributs de sécurité S3 sont des **ressources séparées** depuis le provider AWS v4
- `depends_on` obligatoire entre `aws_s3_bucket_policy` et `aws_s3_bucket_public_access_block`
- `aws_iam_policy_document` génère du JSON IAM depuis HCL — plus propre que du JSON littéral
- `locals {}` évite de répéter une expression calculée plusieurs fois
- `force_destroy = true` uniquement en formation, **jamais en production**
