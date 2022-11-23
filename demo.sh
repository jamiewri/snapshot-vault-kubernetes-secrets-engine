#!/bin/bash

NAMESPACE_INFRA=infra
NAMESPACE_APP=app
NAMESPACE_TFC=tfc

case $1 in
  namespaces)
     echo "deploying kubernetes namespaces"
     kubectl apply -f deploy/namespace
  ;;
  serviceaccount)
     echo "Installing Service accounts and ClusterRoleBindings" 
     kubectl apply -f ./deploy/serviceaccounts/serviceaccount.vault-cluster-admin.yaml
     kubectl apply -f ./deploy/serviceaccounts/clusterrolebinding.vault-cluster-admin.yaml
  ;;
  vault)
    echo "Installing Vault in dev mode"
    helm install \
      -n ${NAMESPACE_INFRA} \
      -f ./deploy/vault/values.yaml \
      --version "0.18.0" \
      vault hashicorp/vault
  ;;
  ingress)
     echo "Install ingress services"
     kubectl apply -f deploy/ingress
  ;;
  tfc-agent)
    # Check if TFC_AGENT_TOKEN has been set.
    if [ -z "$TFC_AGENT_TOKEN" ]; then
      echo "Did not find env var TFC_AGENT_TOKEN. Stopping...."
      exit 1
    else
      echo "TFC_AGENT_TOKEN env var found."
    fi

    echo "Installing TFC Agent Token"
    kubectl create secret generic tfc-token \
      --namespace ${NAMESPACE_TFC} \
      --from-literal=tfc-token=${TFC_AGENT_TOKEN} \
      --dry-run=client \
      -o yaml | \
      kubectl apply -f -

     echo "Installing TFC Agent Deployment"
     kubectl apply -f deploy/tfc-agent
  ;;
  vault-config)
    echo "Configuring the Kubernetes Secrets Engine"
    vault secrets enable kubernetes

    vault write -f kubernetes/config
    
    curl \
        --header "X-Vault-Token: ${VAULT_TOKEN}" \
        ${VAULT_ADDR}/v1/kubernetes/roles/cicd-write \
        -d @./deploy/vault-config/role.cicd-write.json

    vault policy write tfc \
      ./deploy/vault-config/policy.tfc.hcl

  ;;
  *)
    echo "Command not found"
  ;;
esac

