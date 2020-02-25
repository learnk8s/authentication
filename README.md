# Authentication

This is the code repository of the _Authentication_ course in the [Learnk8s Academy](http://academy.learnk8s.io/).

## Contents

- Authentication webhook service (`main.go`)
- Automation scripts (`infra-ldap.sh`, `infra-k8s.sh`, `setup-ldap-server.sh`)

## Authentication webhook

This is the authentication webhook service that you will install in your cluster and that handles the authentication of all requests to your Kubernetes API.

## Automation scripts

Various helper scripts:

- `infra-ldap.sh`: create GCP infrastructure for running an LDAP server
- `setup-ldap-server.sh`: install and configure an LDAP server on the GCP infrastructure created by `infra-ldap.sh`
- `infra-k8s.sh`: create GCP infrastructure for running a Kubernetes cluster
