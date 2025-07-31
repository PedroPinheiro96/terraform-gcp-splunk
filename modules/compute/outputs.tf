output "sh_instance_id" {
  value = google_compute_instance.splunk_servers["sh"].id
}

output "sh_internal_ip" {
  value = google_compute_instance.splunk_servers["sh"].network_interface[0].network_ip
}

output "ind1_instance_id" {
  value = google_compute_instance.splunk_servers["ind1"].id
}

output "ind1_internal_ip" {
  value = google_compute_instance.splunk_servers["ind1"].network_interface[0].network_ip
}

output "ind2_instance_id" {
  value = google_compute_instance.splunk_servers["ind2"].id
}

output "ind2_internal_ip" {
  value = google_compute_instance.splunk_servers["ind2"].network_interface[0].network_ip
}

output "ind3_instance_id" {
  value = google_compute_instance.splunk_servers["ind3"].id
}

output "ind3_internal_ip" {
  value = google_compute_instance.splunk_servers["ind3"].network_interface[0].network_ip
}

output "ds_instance_id" {
  value = google_compute_instance.splunk_servers["ds"].id
}

output "ds_internal_ip" {
  value = google_compute_instance.splunk_servers["ds"].network_interface[0].network_ip
}

output "cm_instance_id" {
  value = google_compute_instance.splunk_servers["cm"].id
}

output "cm_internal_ip" {
  value = google_compute_instance.splunk_servers["cm"].network_interface[0].network_ip
}

output "hf_instance_id" {
  value = google_compute_instance.splunk_servers["hf"].id
}

output "hf_internal_ip" {
  value = google_compute_instance.splunk_servers["hf"].network_interface[0].network_ip
}