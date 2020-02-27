#!/bin/bash
# Create and delete GCP infrastructure for the Kubernetes cluster.

up() {
  # Create VPC network
  gcloud compute networks create k8s

  # Add firewall rule to allow incoming traffic
  # TODO: lock down traffic
  gcloud compute firewall-rules create k8s \
    --network k8s \
    --allow tcp

  # Create compute instance
  gcloud compute instances create k8s \
    --network k8s \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud
}

down() {
  gcloud compute instances delete k8s
  gcloud compute firewall-rules delete k8s
  gcloud compute networks delete k8s
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
