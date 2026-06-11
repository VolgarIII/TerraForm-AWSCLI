# Atelier Module 16 — Organisation Terraform Entreprise

**Contexte choisi :** Startup Gaming / App mobile  
**Étudiant :** Julien  
**Date :** 11/06/2026

---

## 1. Contexte (3 lignes)

> _Décrivez l'entreprise : combien d'équipes, combien d'environnements, quels types de workloads._

- **Équipes :** 3 équipes (backend, data, SRE/platform)
- **Environnements :** 4 (sandbox, dev, staging, prod)
- **Workloads :** Backend API de jeu (scores, matchmaking) + workers de traitement d'événements + base de données PostgreSQL + leaderboard Redis + stockage assets S3 + CDN CloudFront

---

## 2. Choix d'organisation

> _Mono-repo, multi-repo ou hybride ? Justifiez en 2 phrases._

**Choix : Mono-repo**

Justification :
- L'équipe est petite (< 5 équipes), les modules sont encore en construction et les itérations doivent être rapides.
- Un mono-repo permet de tout tester ensemble et de s'assurer qu'un changement de module VPC ne casse pas prod sans que les équipes le voient.

---

## 3. Arborescence ASCII

```
gaming-terraform/
│
├── README.md
├── .pre-commit-config.yaml
├── .github/
│   ├── CODEOWNERS
│   └── workflows/
│       ├── terraform-plan.yml      # CI : plan sur chaque PR
│       ├── terraform-apply.yml     # CD : apply sur merge main
│       └── tfsec.yml
│
├── modules/
│   ├── networking/
│   │   └── vpc/                    # VPC + subnets + NAT + route tables
│   ├── compute/
│   │   ├── ec2-bastion/            # Bastion SSH
│   │   └── ecs-service/            # Service ECS Fargate (API, workers)
│   ├── data/
│   │   ├── rds-postgres/           # Base de données principale
│   │   ├── elasticache-redis/      # Leaderboard / cache
│   │   └── s3-bucket-assets/       # Assets jeu + logs
│   └── security/
│       ├── kms-key/                # Chiffrement RDS / S3
│       └── iam-app-role/           # Rôles IAM pour les services
│
├── envs/
│   ├── sandbox/                    # Expérimentation libre
│   │   ├── backend.tf
│   │   ├── providers.tf
│   │   ├── networking.tf
│   │   ├── compute.tf
│   │   ├── data.tf
│   │   └── terraform.tfvars
│   ├── dev/
│   │   └── (même structure)
│   ├── staging/
│   │   └── (même structure)
│   └── prod/
│       ├── backend.tf              # State S3 prod isolé
│       ├── providers.tf            # default_tags prod
│       ├── locals.tf
│       ├── networking.tf           # module vpc (3 AZ, NAT par AZ)
│       ├── compute.tf              # module ecs-service (API + workers)
│       ├── data.tf                 # module rds (multi-AZ), redis, s3
│       ├── security.tf             # module kms, iam-app-role
│       ├── outputs.tf
│       ├── versions.tf
│       └── terraform.tfvars
│
└── global/
    ├── s3-state/                   # Bucket state + table DynamoDB lock
    ├── iam-sso/                    # Rôles SSO cross-account
    └── route53-public/             # Zone DNS publique du jeu
```

---

## 4. Description des 3 modules

### Module `modules/data/rds-postgres/`

**Responsabilité :** Instancier une base de données RDS PostgreSQL sécurisée.

**Interface minimale (variables d'entrée) :**
```hcl
variable "identifier"              { type = string }
variable "instance_class"          { type = string }  # "db.t3.micro" en dev, "db.r6i.large" en prod
variable "multi_az"                { type = bool }    # false en dev, true en prod
variable "vpc_id"                  { type = string }
variable "subnet_ids"              { type = list(string) }
variable "kms_key_arn"             { type = string; default = null }
variable "backup_retention_period" { type = number; default = 7 }
variable "tags"                    { type = map(string); default = {} }
```

---

### Module `modules/data/elasticache-redis/`

**Responsabilité :** Cluster Redis pour le leaderboard et le cache de session.

**Interface minimale :**
```hcl
variable "cluster_id"      { type = string }
variable "node_type"       { type = string }  # "cache.t3.micro" dev, "cache.r6g.large" prod
variable "num_cache_nodes" { type = number; default = 1 }
variable "vpc_id"          { type = string }
variable "subnet_ids"      { type = list(string) }
variable "tags"            { type = map(string); default = {} }
```

---

### Module `modules/compute/ecs-service/`

**Responsabilité :** Service ECS Fargate (API backend jeu ou worker événements).

**Interface minimale :**
```hcl
variable "service_name"       { type = string }
variable "cluster_arn"        { type = string }
variable "task_definition"    { type = string }
variable "desired_count"      { type = number; default = 2 }
variable "cpu"                { type = number; default = 256 }
variable "memory"             { type = number; default = 512 }
variable "target_group_arn"   { type = string; default = null }
variable "subnet_ids"         { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "tags"               { type = map(string); default = {} }
```

---

## 5. Tags obligatoires

| Tag | Valeur type | Rôle |
|---|---|---|
| `ManagedBy` | `Terraform` | Distingue les ressources Terraform des ressources manuelles |
| `Environment` | `dev` / `staging` / `prod` | Filtrage console + Cost Explorer |
| `Project` | `gaming-backend` | Rattacher au produit |
| `Owner` | `team-backend` / `team-sre` | Qui contacter en cas d'incident |
| `CostCenter` | `GAME-DEV` / `GAME-PROD` | Facturation refacturable par équipe |

**Implémentation via `default_tags` dans le provider :**
```hcl
# envs/prod/providers.tf
provider "aws" {
  region = "eu-west-3"
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Environment = "prod"
      Project     = "gaming-backend"
      Owner       = "team-sre"
      CostCenter  = "GAME-PROD"
    }
  }
}
```

---

## 6. Position sur Terragrunt

**Décision : Pas de Terragrunt au démarrage.**

**Justification :**
- Avec 4 environnements et une équipe < 5, la duplication de `backend.tf` reste gérable (4 fichiers quasi-identiques).
- L'équipe maîtrise encore Terraform pur — ajouter Terragrunt maintenant = double complexité pour les juniors.
- **Point de réévaluation** : introduire Terragrunt si on dépasse 5 environnements ou si la douleur de la duplication devient réelle (> 20 fichiers `backend.tf` à maintenir).

---

## Validation

- [ ] L'arborescence contient `modules/`, `envs/` (dev/staging/prod), `global/`
- [ ] Chaque env a son propre `backend.tf` → state isolé
- [ ] `default_tags` posé dans `providers.tf` de chaque env
- [ ] 3 modules décrits avec leur interface minimale
- [ ] 5 tags obligatoires définis
- [ ] Position Terragrunt justifiée

---

## Points clés retenus

- Pattern `envs/` + `modules/` + `global/` = standard pour 80 % des projets
- Mono-repo tant que < 5 équipes — itérations rapides, tout testable ensemble
- Un state S3 **par environnement** — jamais de state partagé dev/prod
- `default_tags` provider = tags appliqués à toutes les ressources sans exception
- Terragrunt : outil puissant mais à introduire **après** avoir maîtrisé Terraform pur
- Modules groupés par **domaine fonctionnel** (`compute/`, `data/`, `security/`) plutôt qu'à plat
