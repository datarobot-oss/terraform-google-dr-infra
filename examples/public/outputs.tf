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
