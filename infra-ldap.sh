#!/bin/bash
# Create/delete GCP infrastructure for the LDAP server.

up() {
  set -e

  # Create compute instance
  gcloud compute instances create ldap \
    --subnet my-subnet \
    --machine-type n1-standard-1  \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --tags ldap

  # Allow LDAP traffic from other instances in the subnet
  gcloud compute firewall-rules create ldap-internal \
    --network my-net \
    --target-tags ldap \
    --allow tcp:389 \
    --source-ranges 10.0.0.0/16

  # Allow SSH and LDAP traffic from everywhere (for configuration and testing)
  gcloud compute firewall-rules create ldap-admin \
    --network my-net \
    --target-tags ldap \
    --allow tcp:22,tcp:389
}

down() {
  gcloud compute instances delete ldap
  gcloud compute firewall-rules delete ldap-internal ldap-admin
}

usage() {
  echo "USAGE:"
  echo "  $(basename $0) up|down"
}

case "$1" in
  up) up ;;
  down) down ;;
  *) usage && exit 1 ;;
esac
