#!/usr/bin/env bash
gsutil cp gs://${bucket}/hashitools.rpm .
rpm -i hashitools.rpm

echo "datacenter       = \"${dc}\"
server              = true
bootstrap_expect    = 3
leave_on_terminate  = true
# advertise_addr      = \"192.168.0.100\"
data_dir            = \"/opt/consul/data\"
client_addr         = \"0.0.0.0\"
log_level           = \"INFO\"
ui                  = true

# GCP cloud join
retry_join = [\"provider=gce project_name=${project} tag_value=${tag}\"]
#retry_join_wan      = [ wan_join ]

disable_remote_exec = false

connect {
  enabled = true
}

primary_datacenter = \"${dc}\"

acl {
  enabled        = true
  default_policy = \"allow\"
  down_policy    = \"extend-cache\"

  tokens {
    master = \"mybigsecret\"
  }
}" > /etc/consul.d/consul.hcl

sudo systemctl enable consul
sudo systemctl start consul