output "artifact_registry_host" {
  description = "The URL that can be used to log into the artifact registry"
  value       = "${var.region}-docker.pkg.dev"
}

output "artifact_registry_repo" {
  description = "Path to the artifact registry repository"
  value       = module.datarobot_infra.artifact_registry_repo_path
}

output "storage_bucket_name" {
  description = "Name of the GCS storage bucket"
  value       = module.datarobot_infra.storage_bucket_name
}

output "dns_zone_name_servers" {
  description = "Name servers of the DNS zone. Create NS records for these with your domain registrar to delegate the zone."
  value       = module.datarobot_infra.dns_zone_name_servers
}

output "app_service_account_email" {
  description = "Email of the GCP service account to use for workloads running in the cluster. This service account will have permissions to access the storage bucket and artifact registry."
  value       = module.datarobot_infra.datarobot_service_account_email
}

output "app_service_account_key_b64" {
  description = "Base64-encoded JSON key for the application service account. This can be used to authenticate to GCP from workloads running in the cluster, or for local development. Handle with care!"
  value       = base64encode(module.datarobot_infra.datarobot_service_account_key)
  sensitive   = true
}
