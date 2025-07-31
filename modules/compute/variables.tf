variable "zone" {
  description = "AWS Zone"
  type = string
  default = "europe-west2-a"
}

variable "machineType" {
  description = "Instance Machine Type"
  type = string
  default = "e2-medium"
}

variable "machineImage" {
  description = "Instance Machine Image"
  type = string
  default = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2404-noble-amd64-v20250725"
}

variable "diskSize" {
  description = "Disk Size"
  type = string
  default = "30"
}

variable "subnetwork_id" {
  type = string
  default = ""
}

variable "sshKey" {
  description = "SSH pub Key to SSH into Splunk Servers"
  type = string
  sensitive = true
}

variable "serviceAccount" {
  description = "Terraform GCP Service Account"
  type = string
  sensitive = true
}

variable "splunk_servers" {
  type = object({
    sh = list(string)
    ind1 = list(string)
    ind2 = list(string)
    ind3 = list(string)
    ds = list(string)
    cm = list(string)
    hf = list(string)
  })
  default = {
    sh = ["sh","10.0.5.201", "splunk_install_sh.sh"]
    ind1 = ["ind1", "10.0.5.202", "splunk_install_ind.sh"]
    ind2 = ["ind2", "10.0.5.203", "splunk_install_ind.sh"]
    ind3 = ["ind3", "10.0.5.204", "splunk_install_ind.sh"]
    ds = ["ds", "10.0.5.205", "splunk_install_ds.sh"]
    cm = ["cm", "10.0.5.206", "splunk_install_cm.sh"]
    hf = ["hf", "10.0.5.207", "splunk_install_hf.sh"]
  }
}