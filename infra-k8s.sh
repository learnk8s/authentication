#/bin/bash
# Create/delete GCP infrastructure for the Kubernetes cluster.

host_network=10.0.0.0/16
#pod_network=10.244.0.0/16
pod_network=200.200.0.0/16

up() {
  set -e

  # VPC network with custom subnet
  gcloud compute networks create k8s --subnet-mode custom
  gcloud compute networks subnets create k8s --network k8s --range "$host_network"

  # Allow incoming SSH, K8s API server, etcd, and ICMP traffic from anywhere
  gcloud compute firewall-rules create k8s-any-source \
    --network k8s \
    --allow tcp:22,tcp:6443,tcp:2379,icmp

  # Allow all incoming traffic from inside the cluster and VPC network
  gcloud compute firewall-rules create k8s-internal \
    --network k8s \
    --allow tcp,udp,icmp \
    --source-ranges "$host_network","$pod_network"

  # Create compute instance for the cluster nodes
  gcloud compute instances create k8s-master k8s-worker-1 k8s-worker-2 \
    --subnet k8s \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-medium
}

down() {
  gcloud compute instances delete k8s-master k8s-worker-1 k8s-worker-2
  gcloud compute firewall-rules delete k8s-any-source k8s-internal
  gcloud compute networks subnets delete k8s
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
