resource "google_storage_bucket" "repo" {
  name          = "${google_project.vault_project.project_id}-bucket"
  project       = google_project.vault_project.project_id
  storage_class = "NEARLINE"
}

resource "google_storage_bucket_object" "rpm" {
  name   = "hashitools.rpm"
  source = var.rpm_file
  bucket = google_storage_bucket.repo.name
}

resource "google_storage_bucket_iam_member" "iam" {
  bucket = google_storage_bucket.repo.name
  member = "serviceAccount:${google_service_account.vault_kms_service_account.email}"
  role   = "roles/storage.objectViewer"
}

resource "google_compute_instance" "jump_box" {
  name         = "jump-host"
  project      = google_project.vault_project.project_id
  machine_type = var.type
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  //no SSD for POC
  //scratch_disk {}

  network_interface {
    subnetwork = module.vpc.subnets_self_links[0]
    access_config {}
  }
  //
  tags = google_compute_firewall.allow_consul_vault.target_tags
  //
  //  metadata_startup_script = "${data.template_file.init.rendered}"
  metadata = {
    "ssh-keys" = var.ssh_key
  }
  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_compute_instance" "consul_primary" {
  count        = var.nodes
  name         = "consul-pri-${count.index + 1}"
  project      = google_project.vault_project.project_id
  machine_type = var.type
  zone         = var.zone_central[count.index]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  //scratch_disk {}

  network_interface {
    subnetwork = module.vpc.subnets_self_links[0]
  }
  //
  tags = ["allow-cv", var.consul_env["pri"] ]
  //
  metadata_startup_script = data.template_file.consul_pri_template.rendered
  metadata = {
    "ssh-keys" = var.ssh_key
  }
  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }

  depends_on = [google_storage_bucket.repo]
}

resource "google_compute_instance" "vault_primary" {
  count        = var.nodes
  name         = "vault-pri-${count.index + 1}"
  project      = google_project.vault_project.project_id
  machine_type = var.type
  zone         = var.zone_central[count.index]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  //scratch_disk {}

  network_interface {
    subnetwork = module.vpc.subnets_self_links[0]
  }
  //
  tags = google_compute_firewall.allow_consul_vault.target_tags
  //
  metadata_startup_script = data.template_file.vault_pri_template[count.index].rendered
  metadata = {
    "ssh-keys" = var.ssh_key
  }

  service_account {
    email  = google_service_account.vault_kms_service_account.email
    scopes = ["cloud-platform", "compute-rw", "userinfo-email", "storage-ro"]
  }
  allow_stopping_for_update = true

  //wait till rpm gets uploaded to gcs bucket
  depends_on = [google_storage_bucket.repo]

}

resource "google_compute_instance" "consul_secondary" {
  count        = var.nodes
  name         = "consul-sec-${count.index + 1}"
  project      = google_project.vault_project.project_id
  machine_type = var.type
  zone         = var.zone_east[count.index]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  //scratch_disk {}

  network_interface {
    subnetwork = module.vpc.subnets_self_links[1]
  }
  //
  tags = ["allow-cv", var.consul_env["sec"] ]
  //
  metadata_startup_script = data.template_file.consul_sec_template.rendered

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
  metadata = {
    "ssh-keys" = var.ssh_key
  }
  depends_on = [google_storage_bucket.repo]
}

resource "google_compute_instance" "vault_secondary" {
  count        = var.nodes
  name         = "vault-sec-${count.index + 1}"
  project      = google_project.vault_project.project_id
  machine_type = var.type
  zone         = var.zone_east[count.index]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  //scratch_disk {}

  network_interface {
    subnetwork = module.vpc.subnets_self_links[1]
  }
  //
  tags = google_compute_firewall.allow_consul_vault.target_tags
  //
  metadata_startup_script = data.template_file.vault_sec_template[count.index].rendered

  service_account {
    email  = google_service_account.vault_kms_service_account.email
    scopes = ["cloud-platform", "compute-rw", "userinfo-email", "storage-ro"]
  }

  allow_stopping_for_update = true
  metadata = {
    "ssh-keys" = var.ssh_key
  }
  depends_on = [google_storage_bucket.repo]
}

data "template_file" "init" {
  template = file("${path.module}/init.sh.tpl")
  vars = {
    bucket = google_storage_bucket.repo.name
  }
}

data "template_file" "consul_pri_template" {
  template = file("${path.module}/consul-server.tpl")
  vars = {
    tag     = var.consul_env["pri"]
    dc      = "DC1"
    project = google_project.vault_project.project_id
    bucket  = google_storage_bucket.repo.name
  }
}

data "template_file" "consul_sec_template" {
  template = file("${path.module}/consul-server.tpl")
  vars = {
    tag     = var.consul_env["sec"]
    dc      = "DC2"
    project = google_project.vault_project.project_id
    bucket  = google_storage_bucket.repo.name
  }
}

data "template_file" "vault_pri_template" {
  count    = var.nodes
  template = file("${path.module}/template.tpl")
  vars = {
    node_ip = google_compute_instance.consul_primary[count.index].network_interface[0].network_ip
    //need to figure out a smart way to do this
    consul_ip1 = google_compute_instance.consul_primary[0].network_interface[0].network_ip
    consul_ip2 = google_compute_instance.consul_primary[1].network_interface[0].network_ip
    consul_ip3 = google_compute_instance.consul_primary[2].network_interface[0].network_ip
    node_count = count.index + 1
    dc         = "DC1"
    tag        = var.consul_env["pri"]
    bucket     = google_storage_bucket.repo.name
    project    = google_project.vault_project.project_id
    region     = "global"
    key_ring   = google_kms_key_ring.key_ring.name
    crypto_key = google_kms_crypto_key.crypto_key.name
  }
}

data "template_file" "vault_sec_template" {
  count    = var.nodes
  template = file("${path.module}/template.tpl")
  vars = {
    node_ip = google_compute_instance.consul_secondary[count.index].network_interface[0].network_ip
    //need to figure out a smart way to do this
    consul_ip1 = google_compute_instance.consul_secondary[0].network_interface[0].network_ip
    consul_ip2 = google_compute_instance.consul_secondary[1].network_interface[0].network_ip
    consul_ip3 = google_compute_instance.consul_secondary[2].network_interface[0].network_ip
    node_count = count.index + 1
    dc         = "DC2"
    tag        = var.consul_env["sec"]
    bucket     = google_storage_bucket.repo.name
    project    = google_project.vault_project.project_id
    region     = "global"
    key_ring   = google_kms_key_ring.key_ring.name
    crypto_key = google_kms_crypto_key.crypto_key.name
  }
}

//resource "google_compute_forwarding_rule" "vault_primary_fr" {
//  project = google_project.vault_project.project_id
//  name                  = "vault-forwarding-rule"
//  region                = var.region[0]
//  load_balancing_scheme = "EXTERNAL"
//  backend_service       = "${google_compute_region_backend_service.backend.self_link}"
//  all_ports             = true
//  network               = "${module.vpc.network_name}"
//  subnetwork            = module.vpc.subnets_names[0]
//}
//
//resource "google_compute_region_backend_service" "backend" {
//  project = google_project.vault_project.project_id
//  name                  = "vault-backend"
//  region                = var.region[0]
//  health_checks         = ["${google_compute_http_health_check.vault_hc.self_link}"]
//}


