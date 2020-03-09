#!/bin/bash
# Create/delete GCP infrastructure for the LDAP server.

up() {
  set -e

  # Create VPC network
  gcloud compute networks create ldap #--subnet-mode custom
  #gcloud compute networks subnets create ldap --network ldap --range 10.0.0.0/16

  # Add firewall rule to allow incoming SSH and LDAP traffic
  gcloud compute firewall-rules create ldap \
    --network ldap \
    --allow tcp:22,tcp:389

  # Create compute instance
  gcloud compute instances create ldap \
    --network ldap \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-standard-2
}

down() {
  gcloud compute instances delete ldap
  gcloud compute firewall-rules delete ldap
  #gcloud compute networks subnets delete ldap
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
