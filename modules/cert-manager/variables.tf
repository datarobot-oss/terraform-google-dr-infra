variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "google_project_id" {
  description = "The ID of the Google Project where these resources will be created"
  type        = string
}

variable "dns_zone_name" {
  description = "Name of the DNS zone used for certificate validaton"
  type        = string
}

variable "letsencrypt_clusterissuers" {
  description = "Whether to create letsencrypt-prod and letsencrypt-staging ClusterIssuers"
  type        = bool
}

variable "email_address" {
  description = "Email address for the certificate owner. Let's Encrypt will use this to contact you about expiring certificates, and issues related to your account. Only required if letsencrypt_clusterissuers is true."
  type        = string
}

variable "custom_values_templatefile" {
  description = "Custom values templatefile to pass to the helm chart"
  type        = string
  default     = ""
}

variable "custom_values_variables" {
  description = "Variables for the custom values templatefile"
  type        = any
  default     = {}
}
