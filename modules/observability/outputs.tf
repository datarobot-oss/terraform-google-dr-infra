output "service_account_email" {
  description = "The email of the created Google Service Account"
  value       = google_service_account.observability_service_account.email
}
