#!/bin/bash
# Create/delete GCP infrastructure for the authentication service.

up() {
  set -e

  # Create VPC network
  gcloud compute networks create authn --subnet-mode custom
  gcloud compute networks subnets create authn --network authn --range 10.0.0.0/16

  # Add firewall rule to allow incoming HTTPS and SSH traffic
  gcloud compute firewall-rules create authn \
    --network authn \
    --allow tcp:22,tcp:443

  # Create compute instance
  gcloud compute instances create authn \
    --subnet authn \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-small
}

down() {
  gcloud compute instances delete authn
  gcloud compute firewall-rules delete authn
  gcloud compute networks subnets delete authn
  gcloud compute networks delete authn
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
