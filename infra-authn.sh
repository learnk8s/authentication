#!/bin/bash
# Create/delete GCP infrastructure for the authentication service.

up() {
  set -e

  # Create compute instance
  gcloud compute instances create authn \
    --subnet my-subnet \
    --machine-type e2-small \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --tags authn

  # Allow HTTPS traffic from other instances in the subnet
  gcloud compute firewall-rules create authn-internal \
    --network my-net \
    --target-tags authn \
    --allow tcp:443 \
    --source-ranges 10.0.0.0/16

  # Allow SSH and HTTPS traffic from everwhere (for configuration and testing)
  gcloud compute firewall-rules create authn-admin \
    --network my-net \
    --target-tags authn \
    --allow tcp:22,tcp:443
}

down() {
  gcloud compute instances delete authn
  gcloud compute firewall-rules delete authn-internal authn-admin
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
