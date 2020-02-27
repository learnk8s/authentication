#!/bin/bash
# Create and delete GCP infrastructure for the LDAP server.

up() {
  # Create VPC network
  gcloud compute networks create ldap

  # Add firewall rule to allow incoming SSH and LDAP traffic
  gcloud compute firewall-rules create ldap \
    --network ldap \
    --allow tcp:22,tcp:389

  # Create compute instance
  gcloud compute instances create ldap \
    --network ldap \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud
}

down() {
  gcloud compute instances delete ldap
  gcloud compute firewall-rules delete ldap
  gcloud compute networks delete ldap
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
