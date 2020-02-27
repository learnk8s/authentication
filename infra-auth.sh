#!/bin/bash
# Create and delete GCP infrastructure for the webhook authentication service.

up() {
  # Create VPC network
  gcloud compute networks create auth

  # Add firewall rule to allow incoming HTTPS and SSH traffic
  gcloud compute firewall-rules create auth \
    --network auth \
    --allow tcp
    --allow tcp:22,tcp:443

  # Create compute instance
  gcloud compute instances create auth \
    --network auth \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud
}

down() {
  gcloud compute instances delete auth
  gcloud compute firewall-rules delete auth
  gcloud compute networks delete auth
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
