# Learnk8s Academy: Authentication

Code repository of the _Authentication_ course in the [Learnk8s Academy](http://academy.learnk8s.io/).

## Contents

- Authentication service: `authn.go`
- Automation scripts: `infra.sh`, `openldap.sh`

## Authentication service

This is the authentication service used as the endpoint for the [Webhook Token](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#webhook-token-authentication) authentication plugin in the Kubernetes API server.

## Automation scripts

- `infra.sh`: create and delete GCP infrastructure for the individual components of the system
- `openldap.sh`: automate the installation and configuration of the OpenLDAP directory
