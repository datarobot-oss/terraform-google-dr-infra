variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "google_project_id" {
  description = "The ID of the Google Project where these resources will be created"
  type        = string
}

variable "region" {
  description = "The GCP region where the MongoDB Atlas private endpoint should exist"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "subnet" {
  description = "subnet which will host the MongoDB Atlas private endpoint interfaces"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR fo the subnet which will host the MongoDB Atlas private endpoint interfaces"
  type        = string
}

variable "project_ip_access_list" {
  description = "CIDR to add to the MongoDB Atlas project IP access list"
  type        = string
}

variable "mongodb_version" {
  description = "MongoDB version"
  type        = string
}

variable "atlas_org_id" {
  description = "Atlas organization ID"
  type        = string
}

variable "termination_protection_enabled" {
  description = "Enable protection to avoid accidental production cluster termination"
  type        = bool
}

variable "db_audit_enable" {
  type        = bool
  description = "Enable database auditing for production instances only(cost incurred 10%)"
}

variable "atlas_auto_scaling_disk_gb_enabled" {
  description = "Enable Atlas disk size autoscaling"
  type        = bool
}

variable "atlas_disk_size" {
  description = "Starting atlas disk size"
  type        = string
}

variable "atlas_instance_type" {
  description = "atlas instance type"
  type        = string
}

variable "mongodb_admin_username" {
  description = "MongoDB admin username"
  type        = string
}

variable "enable_slack_alerts" {
  description = "Enable alert notifications to a Slack channel. When `true`, `slack_api_token` and `slack_notification_channel` must be set."
  type        = string
  default     = false
}

variable "slack_api_token" {
  description = "Slack API token to use for alert notifications. Required when `enable_slack_alerts` is `true`."
  type        = string
  default     = null
}

variable "slack_notification_channel" {
  description = "Slack channel to send alert notifications to. Required when `enable_slack_alerts` is `true`."
  type        = string
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all created resources"
  type        = map(string)
}

variable "network_reservation_ip_offset" {
  type        = number
  description = "Value to offset the network reservation IP"
}
