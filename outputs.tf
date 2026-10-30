################################################################################
# Network
################################################################################

output "vpc_name" {
  description = "Name of the VPC"
  value       = try(module.network[0].network_name, null)
}


################################################################################
# DNS
################################################################################

output "public_dns_zone_name" {
  description = "Name of the public DNS zone"
  value       = local.public_dns_zone_name
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  value       = local.private_dns_zone_name
}

output "public_dns_zone_name_servers" {
  description = "Name servers of the public DNS zone"
  value       = local.public_zone_name_servers
}

################################################################################
# Storage
################################################################################

output "storage_bucket_name" {
  description = "Name of the storage bucket"
  value       = try(module.storage[0].name, null)
}


################################################################################
# Container Registry
################################################################################

output "artifact_registry_repo_id" {
  description = "ID of the Artifact Registry repository"
  value       = try(google_artifact_registry_repository.this[0].id, null)
}

output "artifact_registry_repo_path" {
  description = "Path to the Artifact Registry repository"
  value       = try("${var.google_project_id}/${google_artifact_registry_repository.this[0].name}", null)
}


################################################################################
# Pull-Through Cache
################################################################################

output "pull_through_cache_registry_url" {
  description = "Registry URL to pull Docker Hub images through the Artifact Registry remote repository, e.g. <url>/<namespace>/<image>:<tag>"
  value       = try("${var.region}-docker.pkg.dev/${var.google_project_id}/${google_artifact_registry_repository.pull_through_cache[0].repository_id}", null)
}

output "pull_through_cache_repository_id" {
  description = "ID of the Artifact Registry remote repository"
  value       = try(google_artifact_registry_repository.pull_through_cache[0].id, null)
}

################################################################################
# Kubernetes
################################################################################

output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = try(module.kubernetes[0].name, null)
}


################################################################################
# App Identity
################################################################################

output "datarobot_service_account_email" {
  description = "Email of the DataRobot service account"
  value       = try(module.app_identity[0].email, null)
}

output "datarobot_service_account_key" {
  description = "DataRobot service account key"
  sensitive   = false
  value       = try(module.app_identity[0].key, null)
}


################################################################################
# PostgreSQL
################################################################################

output "postgres_endpoint" {
  description = "PostgreSQL endpoint"
  value       = try(module.postgres[0].private_ip_address, null)
}

output "postgres_password" {
  description = "PostgreSQL admin password"
  value       = try(module.postgres[0].generated_user_password, null)
  sensitive   = true
}


################################################################################
# Redis
################################################################################

output "redis_endpoint" {
  description = "Google Memorystore Redis endpoint"
  value       = try(module.redis[0].host, null)
}

output "redis_port" {
  description = "Google Memorystore Redis port"
  value       = try(module.redis[0].port, null)
}

output "redis_password" {
  description = "Google Memorystore Redis instance primary access key"
  value       = try(module.redis[0].auth_string, null)
  sensitive   = true
}

################################################################################
# MongoDB
################################################################################

output "mongodb_endpoint" {
  description = "MongoDB endpoint"
  value       = try(module.mongodb[0].endpoint, null)
}

output "mongodb_password" {
  description = "MongoDB admin password"
  value       = try(module.mongodb[0].password, null)
  sensitive   = true
}
