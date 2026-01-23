variable "name" {
  description = "Name to use as a prefix for created resources"
  type        = string
}

variable "project_id" {
  description = "The ID of the Google Project where these resources will be created"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace in which the DataRobot application will be installed"
  type        = string
}
