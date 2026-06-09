output "bucket_name" {
  value       = aws_s3_bucket.main.id
  description = "Nom du bucket S3"
}

output "bucket_arn" {
  value       = aws_s3_bucket.main.arn
  description = "ARN complet du bucket"
}

output "bucket_region" {
  value       = aws_s3_bucket.main.region
  description = "Region AWS du bucket"
}

output "versioning_status" {
  value       = aws_s3_bucket_versioning.main.versioning_configuration[0].status
  description = "Statut du versioning"
}
