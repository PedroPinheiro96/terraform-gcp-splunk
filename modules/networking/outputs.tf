output "vpc_name" {
  description = "Name of the VPC"
  value       = google_compute_network.splunk_vpc.name
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = google_compute_subnetwork.splunk_subnet.name
}

output "splunk_subnet_id" {
  description = "Subnet ID"
  value       = google_compute_subnetwork.splunk_subnet.id
}

output "subnet_cidr_range" {
  description = "IPv4 range of the subnet"
  value       = google_compute_subnetwork.splunk_subnet.ip_cidr_range
}