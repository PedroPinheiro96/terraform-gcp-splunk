variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type    = string
  default = "europe-west2"
}

#Service Account Private Key referenced in terraform.tfvars
variable "serviceAccount_key" {
  description = "Path to the GCP service account key file"
  type        = string
  sensitive   = true
}

#It's also here to be able to configure it in terraform.tfvars
variable "pubIP" {
  description = "Your Public IP"
  default     = ["0.0.0.0"]
  type        = set(string)
  sensitive   = true
}

variable "sshKey" {
  description = "SSH pub Key to SSH into Splunk Servers"
  type        = string
  sensitive   = true
}

variable "serviceAccount" {
  description = "Terraform GCP Service Account"
  type        = string
  sensitive   = true
}