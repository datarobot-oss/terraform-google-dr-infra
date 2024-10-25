output "artifact_registry_host" {
  description = "The URL that can be used to log into the artifact registry"
  value       = "${local.region}-docker.pkg.dev"
}

output "artifact_registry_repo" {
  description = "Path to the artifact registry repository"
  value       = module.datarobot_infra.artifact_registry_repo_path
}

output "storage_bucket_name" {
  description = "Name of the GCS storage bucket"
  value       = module.datarobot_infra.storage_bucket_name
}

output "service_account_email" {
  description = "IAM member email address of the service account created for the DataRobot application"
  value       = module.datarobot_infra.datarobot_service_account_email
}

output "service_account_key" {
  description = "Base64-encoded key of the service account created for the DataRobot application"
  value       = nonsensitive(base64encode(module.datarobot_infra.datarobot_service_account_key))
}
