#/bin/bash
# Create/delete GCP infrastructure for the Kubernetes cluster.

up() {
  set -e

  # Create compute instances for master and worker nodes
  gcloud compute instances create k8s-master k8s-worker-1 k8s-worker-2 \
    --subnet my-subnet \
    --machine-type e2-medium \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --tags k8s

  # Allow all traffic from other cluster nodes
  gcloud compute firewall-rules create k8s-internal \
    --network my-net \
    --target-tags k8s \
    --allow tcp,udp,icmp \
    --source-tags k8s

  # Allow TCP, etcd, ICMP traffic from everywhere (for installation)
  gcloud compute firewall-rules create k8s-install \
    --network my-net \
    --target-tags k8s \
    --allow tcp:22,tcp:2379,icmp

  # Allow Kubernetes API server traffic from everywhere
  gcloud compute firewall-rules create k8s-access \
    --network my-net \
    --target-tags k8s \
    --allow tcp:6443
}

down() {
  gcloud compute instances delete k8s-master k8s-worker-1 k8s-worker-2
  gcloud compute firewall-rules delete k8s-internal k8s-install k8s-access
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
