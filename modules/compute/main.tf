resource "google_compute_instance" "splunk_servers" {
  
  for_each = var.splunk_servers

  name = each.value[0]
  machine_type = var.machineType
  zone = var.zone
  
  boot_disk {
    auto_delete = true
    device_name = each.value[0]
    initialize_params {
      image = var.machineImage
      size = var.diskSize
      type = "pd-standard"
    }
  }

  network_interface {
    subnetwork = var.subnetwork_id
    network_ip = each.value[1]
    stack_type = "IPV4_ONLY"
    queue_count = 0
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    enable-osconfig = "TRUE"
    ssh-keys = var.sshKey
  }

  metadata_startup_script = file("scripts/${each.value[2]}")

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = var.serviceAccount
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }
}