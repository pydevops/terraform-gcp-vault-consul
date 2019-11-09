variable "region" {
  type = "list"
  default = [
    "us-central1",
    "us-west1",
    "us-east1",
    "us-east4",
  ]
}

variable "billing_account" {
  type    = "string"
  default = "0105E1-61A6DE-D85D10"
}

variable "folder_id" {
  type    = "string"
  default = "738401585299"
}

variable "project_name" {
  default = "vault-demo-project"
}

variable "auto_create_network" {
  type    = "string"
  default = "true"
}

variable "apis" {
  type = "list"

  default = [
    "compute.googleapis.com",
    "storage-api.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "servicemanagement.googleapis.com",
    "container.googleapis.com",
    "cloudkms.googleapis.com",
    "sql-component.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudkms.googleapis.com",
  ]
}

variable "skip_delete" {
  type    = "string"
  default = "false"
}

variable "type" {
  default = "g1-small"
}

variable "zone_east" {
  type = "list"
  default = [
    "us-east1-b",
    "us-east1-c",
    "us-east1-d",
  ]
}

variable "zone_central" {
  type = "list"
  default = [
    "us-central1-a",
    "us-central1-b",
    "us-central1-c"
  ]
}

variable "ssh_key" {
  default = "awolde:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCupU7f2tOd+88jyUHg0JrB2oHFNKV1Pl+wnJzMAv35zM3EZtYrMmv2B4oLDFa9Mjd3+r34DPnWR5Gw6brxOgiZ0GdvhNA9iuKpvcxkRRQTLX5JHy9dRxrvljpEGPnDRFKrS2ADYTv2yHbOkJNc8QHF1gype0Vw5sfM+1cPSvVj7YhIGRn+NqQMbbpcMcBm8woVK96rBdYDHBWXboWyJUIKYsPD325l1UtM8AsMlHrEGXu0P0moqfYSYxYWak0DATwdHKwXJsSm5m2g+kECB4dbKHNhIUjWA/cEw7gaLoUaXOESHdyfxftn/6DGtlh7HCFe/dq36YladYzwvslJOhT/ amang@amang-OptiPlex-3010"
}

variable "nodes" {
  default = "3"
}

variable "rpm_file" {
  default = "./hashitools.rpm"
}

variable "consul_env" {
  type = "map"
  default = {
    "pri" = "primary-consul"
    "sec" = "secondary-consul"
  }
}