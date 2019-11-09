#!/usr/bin/env bash
gsutil cp gs://${bucket}/hashitools.rpm .
rpm -i hashitools.rpm

echo "ui=true

listener \"tcp\" {
  address          = \"0.0.0.0:8200\"
  cluster_address  = \"REPLACE_ME:8201\"
  tls_disable      = \"true\"
}

storage \"consul\" {
  address = \"127.0.0.1:8500\"
  path    = \"valu/\"
}

seal \"gcpckms\" {
    project     = \"${project}\"
    region      = \"${region}\"
    key_ring    = \"${key_ring}\"
    crypto_key  = \"${crypto_key}\"
}

api_addr = \"http://REPLACE_ME:8200\"
cluster_addr = \"https://REPLACE_ME:8201\"
" > /etc/vault.d/vault.hcl

echo "datacenter    = \"${dc}\"
server              = false
node_name           = \"vault-${tag}-${node_count}\"
leave_on_terminate  = true
data_dir            = \"/opt/consul/vault\"
client_addr         = \"127.0.0.1\"
log_level           = \"INFO\"
retry_join          = [\"${consul_ip1}\", \"${consul_ip2}\", \"${consul_ip3}\"]
enable_syslog = true
acl_enforce_version_8 = false
" > /etc/consul.d/consul.hcl

echo -e 'export VAULT_ADDR="http://127.0.0.1:8200"' > /etc/profile.d/vault.sh
IP=$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip -H "Metadata-Flavor: Google")
sed -i 's/REPLACE_ME/'$IP'/g' /etc/vault.d/vault.hcl
sudo chown consul: /opt/consul -R
sudo systemctl enable consul
sudo systemctl start consul
sudo systemctl enable vault
sudo systemctl start vault
sleep 5
export VAULT_ADDR="http://127.0.0.1:8200"
#/usr/local/bin/vault operator init -recovery-shares=1 -recovery-threshold=1 > /root/recovery-keys
