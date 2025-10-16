terraform {
  backend "azurerm" {}
}

# leveraging backend config files
# terraform init -backend-config=backend-config.hcl

# Notes on leveraging more hard-coded backend.tf
# IMPORTANT: Replace "sttfstate" with actual storage account name
# Get it from the bootstrap script output or run:
# az storage account list --resource-group rg-terraform-state --query "[0].name" -o tsv
