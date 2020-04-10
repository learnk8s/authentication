#!/bin/bash
#
# Create and delete GCP infrastructure.
#
# Usage:
#  
#  infra.sh up|down [network|ldap|authn|k8s]...
#
#------------------------------------------------------------------------------#

action=$1
shift
components=${*:-network ldap authn k8s}

usage() {
  cat <<EOF
USAGE
  $(basename $0) up|down [network|ldap|authn|k8s]...

NOTE
  If only a single argument is provided (up or down), then all components
  are assumed (network, ldap, authn, and k8s).

EXAMPLES
  # Spin up the network and LDAP infrastructure
  $(basename $0) up network ldap

  # Delete all infrastructure
  $(basename $0) down
EOF
}

# Network infrastructure for the other components
network-up() {
  gcloud compute networks create my-net --subnet-mode custom
  gcloud compute networks subnets create my-subnet --network my-net --range 10.0.0.0/16
}
network-down() {
  gcloud compute networks subnets delete my-subnet
  gcloud compute networks delete my-net
}

# Infrastructure for the LDAP server
ldap-up() {
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
ldap-down() {
  gcloud compute instances delete ldap
  gcloud compute firewall-rules delete ldap-internal ldap-admin
}

# Infrastructure for the authentication service
authn-up() {
  gcloud compute instances create authn \
    --subnet my-subnet \
    --machine-type e2-small \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --tags authn
  # Allow HTTPS traffic from the Kubernetes cluster nodes
  gcloud compute firewall-rules create authn-internal \
    --network my-net \
    --target-tags authn \
    --allow tcp:443 \
    --source-tags k8s
  # Allow SSH and HTTPS traffic from everwhere (for configuration and testing)
  gcloud compute firewall-rules create authn-admin \
    --network my-net \
    --target-tags authn \
    --allow tcp:22,tcp:443
}
authn-down() {
  gcloud compute instances delete authn
  gcloud compute firewall-rules delete authn-internal authn-admin
}

# Infrastructure for the Kubernetes cluster
k8s-up() {
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
k8s-down() {
  gcloud compute instances delete k8s-master k8s-worker-1 k8s-worker-2
  gcloud compute firewall-rules delete k8s-internal k8s-install k8s-access
}

# Entry point
case "$action" in
  up)
    set -e
    [[ "$components" =~ network ]] && network-up
    [[ "$components" =~ ldap ]] && ldap-up
    [[ "$components" =~ authn ]] && authn-up
    [[ "$components" =~ k8s ]] && k8s-up
    ;;
  down)
    [[ "$components" =~ k8s ]] && k8s-down
    [[ "$components" =~ authn ]] && authn-down
    [[ "$components" =~ ldap ]] && ldap-down
    [[ "$components" =~ network ]] && network-down
    ;;
  *)
    usage && exit 1
    ;;
esac
