variable "project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
}


variable "environment" {
  default = "prod"
}

variable "tf_state_bucket" {
  description = "The name of the Google Cloud Storage bucket for Terraform state."
  type        = string
}