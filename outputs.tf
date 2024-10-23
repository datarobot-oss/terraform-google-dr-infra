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
  value       = try(module.public_dns[0].name, null)
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  value       = try(module.private_dns[0].name, null)
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
