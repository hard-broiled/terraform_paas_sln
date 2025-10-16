#!/usr/bin/env bash
set -euo pipefail

# USAGE:
# ./bootstrap_backend.sh <subscription-id> <backend-rg> <storage-account-name> <container-name> <location>
# example:
# ./bootstrap_backend.sh 11111111-aaaa-2222-bbbb tfstate-rg tfstatecde01 tfstate eastus

SUBSCRIPTION_ID=${1:?Give subscription id}
BACKEND_RG=${2:-tfstate-rg}
STORAGE_ACCOUNT=${3:?Give globally-unique storage account name}
CONTAINER=${4:-tfstate}
LOCATION=${5:-eastus}

echo "Using subscription: $SUBSCRIPTION_ID"
az account set --subscription "$SUBSCRIPTION_ID"

echo "Creating resource group $BACKEND_RG (if not exists)..."
az group create -n "$BACKEND_RG" -l "$LOCATION" --subscription "$SUBSCRIPTION_ID"

echo "Creating storage account $STORAGE_ACCOUNT..."
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$BACKEND_RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --https-only true \
  --kind StorageV2

echo "Enabling blob versioning and soft-delete..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --enable-versioning true

az storage blob service-properties delete-policy update \
  --account-name "$STORAGE_ACCOUNT" \
  --enable true \
  --days-retained 365

echo "Getting storage account key..."
ACCOUNT_KEY=$(az storage account keys list --account-name "$STORAGE_ACCOUNT" --resource-group "$BACKEND_RG" --query "[0].value" -o tsv)

echo "Creating container $CONTAINER..."
az storage container create --name "$CONTAINER" --account-name "$STORAGE_ACCOUNT" --account-key "$ACCOUNT_KEY"

echo "Backend bootstrap complete. Storage account: $STORAGE_ACCOUNT, container: $CONTAINER"
echo "Configure your envs/*/backend.tf variables to use this storage account and RG."
