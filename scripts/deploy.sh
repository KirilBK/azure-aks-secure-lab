#!/usr/bin/env bash
# deploy.sh — end-to-end manual deploy after `terraform apply`.
# Reads Terraform outputs and substitutes the REPLACE_WITH_* placeholders in
# the app1 manifests, then builds/pushes the image and applies everything.
set -euo pipefail

cd "$(dirname "$0")/.."
TF=infra

echo "==> Reading Terraform outputs"
ACR_LOGIN=$(terraform -chdir=$TF output -raw acr_login_server)
ACR_NAME=$(terraform -chdir=$TF output -raw acr_name)
AKS_NAME=$(terraform -chdir=$TF output -raw aks_name)
RG=$(terraform -chdir=$TF output -raw resource_group)
KV_NAME=$(terraform -chdir=$TF output -raw key_vault_name)
KV_TENANT=$(terraform -chdir=$TF output -raw key_vault_tenant_id)
APP1_CLIENT_ID=$(terraform -chdir=$TF output -raw app1_workload_identity_client_id)

echo "==> Building and pushing app1 image via ACR Tasks"
az acr build --registry "$ACR_NAME" --image app1:latest ./app1

echo "==> Getting AKS credentials"
az aks get-credentials --name "$AKS_NAME" --resource-group "$RG" --overwrite-existing
kubelogin convert-kubeconfig -l azurecli

echo "==> Rendering manifests"
TMP=$(mktemp -d)
cp app1/manifests/*.yaml "$TMP"/
sed -i "s#REPLACE_WITH_app1_workload_identity_client_id#$APP1_CLIENT_ID#g" "$TMP"/*.yaml
sed -i "s#REPLACE_WITH_key_vault_name#$KV_NAME#g"                          "$TMP"/*.yaml
sed -i "s#REPLACE_WITH_key_vault_tenant_id#$KV_TENANT#g"                   "$TMP"/*.yaml
sed -i "s#REPLACE_WITH_acr_login_server#$ACR_LOGIN#g"                      "$TMP"/*.yaml

echo "==> Applying manifests"
kubectl apply -f "$TMP"/00-namespace.yaml
kubectl apply -f "$TMP"/

echo "==> Done. Ingress IP:"
kubectl get ingress -n app1
