provider "vault" {
  //address = "${var.vault_addr}"
  //  token   = "${var.token}"
  //  token = "s.83dk7zFBWxdmIfw3tQzi4Bxe"
}

variable "vault_addr" {
  default = "http://localhost:8200"
}

variable "user_dn" {
  default = "OU=User Accounts,DC=example,DC=com"
}

variable "group_dn" {
  default = "OU=Groups,DC=example,DC=com"
}

variable "bind_dn" {
  default = "CN=Vault LDAP,OU=Service Accounts,DC=example,DC=com"
}

resource "vault_ldap_auth_backend" "ldap" {
  path           = "ldap"
  description    = "LDAP auth"
  url            = "ldap://127.0.0.1:389"
  userdn         = "${var.user_dn}"
  userattr       = "samaccountName"
  discoverdn     = "false"
  groupdn        = "${var.group_dn}"
  groupfilter    = "(&(objectClass=group)(member:1.2.840.113556.1.4.1941:={{.UserDN}}))"
  binddn         = "${var.bind_dn}"
  bindpass       = "somepass"
  groupattr      = "cn"
  insecure_tls   = "false"
  starttls       = "false"
  deny_null_bind = "true"
}

resource "vault_auth_backend" "user_pass" {
  type = "userpass"
  path = "userpass"
}

resource "vault_generic_secret" "users" {
  data_json = <<EOT
  {
    "user": "cheese",
    "password": "pass",
    "policies": "${vault_policy.kv_policy.name},default"
  }
EOT
  path      = "/auth/userpass/users/cheese"
}

resource "vault_gcp_secret_backend" "gcp" {
  credentials           = "${file("credentials.json")}"
  max_lease_ttl_seconds = 10
  path                  = "gcp"
}

variable "project" {
  default = "vault-demo-project-bsck"
}

resource "vault_gcp_secret_roleset" "roleset" {
  backend      = "${vault_gcp_secret_backend.gcp.path}"
  roleset      = "storage_admin"
  secret_type  = "service_account_key"
  project      = var.project
  token_scopes = ["https://www.googleapis.com/auth/cloud-platform"]


  binding {
    resource = "//cloudresourcemanager.googleapis.com/projects/${var.project}"

    roles = [
      "roles/storage.admin"
    ]
  }
}

resource "vault_policy" "kv_policy" {
  name = "gcp-secrets"

  policy = <<EOT
    path "${vault_gcp_secret_backend.gcp.path}/key/${vault_gcp_secret_roleset.roleset.roleset}" {
      capabilities = [ "create", "read", "update", "delete", "list", "sudo"]
    }

    path "auth/token/*" {
      capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
    }
    EOT
}

resource "vault_token_auth_backend_role" "example" {
  role_name              = "token-role"
  allowed_policies       = ["gcp-secrets", "test"]
  disallowed_policies    = ["default"]
  orphan                 = true
  token_period           = "3600"
  renewable              = true
  token_explicit_max_ttl = "115200"
  //  path_suffix         = "path-suffix"
}

//resource "vault_token" "example" {
//  role_name = "app"
//
//  policies = ["gcp-secrets"]
//
//  renewable = true
//  ttl = "1h"
//
//  renew_min_lease = 43200
//  renew_increment = 86400
//}

