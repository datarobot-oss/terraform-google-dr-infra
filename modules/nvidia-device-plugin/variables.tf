variable "chart_version" {
  description = "Version or semver range of the helm chart to install"
  type        = string
}

variable "values_overrides" {
  description = "Values in raw yaml format to pass to helm."
  type        = string
  default     = null
}
