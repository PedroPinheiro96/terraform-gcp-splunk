#Create the VPC Network
resource "google_compute_network" "splunk_vpc" {
  description = "Custom VPC for Splunk Environment"
  name = "splunk-vpc"
  auto_create_subnetworks = false
}

#Create the subnet
resource "google_compute_subnetwork" "splunk_subnet" {
  name          = "splunk-subnet"
  region        = var.region
  ip_cidr_range = var.ipv4_range
  network       = google_compute_network.splunk_vpc.name
}

#Allow Splunk to Splunk ports
resource "google_compute_firewall" "allow_splunk_ports" {
  name    = "allow-splunk-ports"
  network = google_compute_network.splunk_vpc.name
  description = "Ports necessary for Splunk to run"
  source_ranges = setunion(var.pubIP, var.cidr_range)
  destination_ranges = var.cidr_range

  allow {
    protocol = "tcp"
    ports    = ["8089", "8191", "9887", "9997", "8065", "8181"]
  }
}

#Allow Splunk to communicate with the UF
resource "google_compute_firewall" "allow_splunk_ports_egress" {
  name    = "allow-splunk-ports-egress"
  network = google_compute_network.splunk_vpc.name
  description = "Ports necessary for Splunk to run"
  source_ranges = setunion(var.dsIP, var.hfIP)
  destination_ranges = var.pubIP
  direction = "EGRESS"

  allow {
    protocol = "tcp"
    ports    = ["8089", "9997"]
  }
}

#Only allow access to the splunk GUI from my public IP
resource "google_compute_firewall" "allow_splunk_web" {
  name    = "allow-splunk-web"
  network = google_compute_network.splunk_vpc.name
  description = "Splunk Web"
  source_ranges = var.pubIP
  destination_ranges = var.cidr_range

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }
}

#Only allow SSH from my public IP
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.splunk_vpc.name
  description = "Allows ssh on port 22"
  source_ranges = var.pubIP
  destination_ranges = var.cidr_range

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}