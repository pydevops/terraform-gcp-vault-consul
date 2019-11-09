resource "google_service_account" "vault_kms_service_account" {
  account_id   = "vault-gcpkms"
  display_name = "Vault KMS for auto-unseal"
  project      = google_project.vault_project.project_id
}

resource "google_kms_key_ring" "key_ring" {
  project  = google_project.vault_project.project_id
  name     = "vt-keyring"
  location = "global"
}

# Create a crypto key for the key ring
resource "google_kms_crypto_key" "crypto_key" {
  name            = "vault-key"
  key_ring        = google_kms_key_ring.key_ring.self_link
  rotation_period = "100000s"
}

resource "google_kms_key_ring_iam_binding" "vault_iam_kms_binding" {
  # key_ring_id = "${google_kms_key_ring.key_ring.id}"
  key_ring_id = "${google_project.vault_project.project_id}/global/${google_kms_key_ring.key_ring.name}"
  role        = "roles/owner"

  members = [
    "serviceAccount:${google_service_account.vault_kms_service_account.email}",
  ]
}
