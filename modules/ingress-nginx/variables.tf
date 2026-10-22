variable "internet_facing_ingress_lb" {
  description = "Connect to the DataRobot application via an complete load balancer"
  type        = bool
}

variable "chart_version" {
  description = "Version of the helm chart to install"
  type        = string
}

variable "values_overrides" {
  description = "Values in raw yaml format to pass to helm."
  type        = string
  default     = null
}
