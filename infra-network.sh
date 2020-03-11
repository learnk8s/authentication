#!/bin/bash
# Create/delete VPC network and subnet for the rest of the GCP infrastructure

up() {
  set -e

  # Create VPC network
  gcloud compute networks create my-net --subnet-mode custom

  # Create subnet
  gcloud compute networks subnets create my-subnet --network my-net --range 10.0.0.0/16
}

down() {
  gcloud compute network subnets delete my-subnet
  gcloud compute network delete my-net
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
