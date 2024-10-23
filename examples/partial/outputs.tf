output "service_account_email" {
  description = "IAM member email address of the service account created for the DataRobot application"
  value       = module.datarobot_infra.datarobot_service_account_email
}

output "service_account_key" {
  description = "Base64-encoded key of the service account created for the DataRobot application"
  value       = nonsensitive(base64encode(module.datarobot_infra.datarobot_service_account_key))
}
