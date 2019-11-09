resource "google_project" "vault_project" {
  name                = "${var.project_name}"
  project_id          = "${var.project_name}-${random_string.suffix.result}"
  folder_id           = "${var.folder_id}"
  billing_account     = "${var.billing_account}"
  auto_create_network = "${var.auto_create_network}"
  skip_delete         = "${var.skip_delete}"
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_project_service" "services" {
  //might need to change this to tf 0.12 for_each
  count   = "${length(var.apis)}"
  service = "${element(var.apis, count.index)}"
  project = "${google_project.vault_project.project_id}"
  disable_on_destroy = false
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 1.4.0"
  project_id   = "${google_project.vault_project.project_id}"
  network_name = "${google_project.vault_project.project_id}-ntk"

  subnets = [
    {
      subnet_name           = "subnet1"
      subnet_ip             = "10.11.0.0/16"
      subnet_region         = "${var.region[0]}"
      subnet_private_access = "true"
    },
    {
      subnet_name           = "subnet2"
      subnet_ip             = "10.12.0.0/16"
      subnet_region         = "${var.region[2]}"
      subnet_private_access = "true"
    },
  ]
  secondary_ranges = {
    "subnet1" = []
    "subnet2" = []
  }
}

resource "google_compute_firewall" "allow_consul_vault" {
  name    = "allow-cv"
  network = module.vpc.network_name
  project = google_project.vault_project.project_id

  allow {
    //    protocol = "all"
    protocol = "tcp"
    //    ports    = []
    ports = ["8200", "8500", "8300", "8301", "8302", "22", "8201"]
  }

  target_tags   = ["allow-cv"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_forwarding_rule" "vault_primary_fr" {
  project               = google_project.vault_project.project_id
  region                = var.region[0]
  load_balancing_scheme = "EXTERNAL"
  //  network               = module.vpc.network_name
  name                  = "vault-forwarding-rule"
  target                = google_compute_target_pool.vault_tp.self_link
  port_range            = 8200
}

resource "google_compute_target_pool" "vault_tp" {
  name    = "vault-pool"
  project = google_project.vault_project.project_id
  region  = var.region[0]

  instances = google_compute_instance.vault_primary[*].self_link

  health_checks = [
    google_compute_http_health_check.vault_hc.name,
  ]
}

resource "google_compute_http_health_check" "vault_hc" {
  project            = google_project.vault_project.project_id
  name               = "vault-check"
  request_path       = "/v1/sys/health"
  check_interval_sec = 2
  timeout_sec        = 1
  port               = 8200
}