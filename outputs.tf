output "bucket" {
  value = google_storage_bucket.repo.name
}

output "vault_sec_node_ips" {
  value = [
    for ip in google_compute_instance.vault_secondary[*].network_interface[0].network_ip :
    "http://${ip}:8200"
  ]
}

output "vault_pri_node_ips" {
  value = [
    for ip in google_compute_instance.vault_primary[*].network_interface[0].network_ip :
    "http://${ip}:8200"
  ]
}

output "consul_pri_ips" {
  value = [
    for ip in google_compute_instance.consul_primary[*].network_interface[0].network_ip :
    "http://${ip}:8500"
  ]
}

output "consul_sec_ips" {
  value = [
    for ip in google_compute_instance.consul_secondary[*].network_interface[0].network_ip :
    "http://${ip}:8500"
  ]
}