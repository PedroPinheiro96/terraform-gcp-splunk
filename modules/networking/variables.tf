variable "vpcname" {
  type = string
  default = "splunk-vpc"
}

variable "region" {
  type    = string
  default = "europe-west2"
}

variable "ipv4_range" {
  type = string
  default = "10.0.5.0/24"
}

variable "cidr_range" {
  type = set(string)
  default = [ "10.0.5.0/24" ]
}

variable "pubIP" {
  description = "Your Public IP"
  default = ["0.0.0.0"]
  type = set(string)
  sensitive = true
}

variable "dsIP" {
  type = set(string)
  default = [ "10.0.5.205" ]
}

variable "hfIP" {
  type = set(string)
  default = [ "10.0.5.207" ]
}