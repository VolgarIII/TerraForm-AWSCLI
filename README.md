# Formation Terraform — AWS

Travaux pratiques Terraform réalisés dans le cadre de la formation.

> Étudiant : étudiant09

---

## TPs réalisés

| TP | Description | Statut |
|---|---|---|
| [tp01](./tp01/) | Bucket S3 sécurisé (versioning, SSE-S3, block public, TLS) | ✅ |
| [tp02](./tp02/) | VPC complet 2 AZ (subnets pub/priv, IGW, NAT, route tables, SG bastion) | ✅ |
| [tp03](./tp03/) | Application web EC2 (bastion + 2 web EC2, nginx, templatefile, key pair) | 🚧 |

---

## Prérequis communs

- Terraform >= 1.7.0 (via tfenv)
- AWS CLI v2 + profil `formation` configuré
- TFLint >= 0.50.0
- VS Code + extension HashiCorp Terraform
