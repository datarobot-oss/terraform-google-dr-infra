locals {
  connection_strings = [
    for pe in mongodbatlas_advanced_cluster.this.connection_strings.private_endpoint : pe.srv_connection_string
    if contains([for e in pe.endpoints : e.endpoint_id], var.vpc_name)
  ]
}

output "endpoint" {
  description = "MongoDB Atlas private endpoint SRV connection string"
  value       = length(local.connection_strings) > 0 ? local.connection_strings[0] : ""
}

output "password" {
  description = "MongoDB Atlas admin password"
  value       = random_password.admin.result
  sensitive   = true
}
