variable "project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
}

variable "service_account" {
  description = "The email of the service account to impersonate."
  type        = string  
}