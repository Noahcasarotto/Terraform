# variables.tf
variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "The GCP region for the Cloud Function"
  type        = string
  default     = "us-central1"
}