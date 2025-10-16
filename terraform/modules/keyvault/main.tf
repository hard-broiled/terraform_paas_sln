data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = var.kv_name
  location                   = var.location
  resource_group_name        = var.rg_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
  
  # Use RBAC for access control (more granular than access policies)
  #enable_rbac_authorization = true
  
  # Disable public access - force private endpoint
  public_network_access_enabled = false

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

# Private endpoint for Key Vault
resource "azurerm_private_endpoint" "kv_pe" {
  name                = "${var.kv_name}-pe"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.kv_name}-psc"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

# Store SQL admin password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.this.id
  
  depends_on = [
    azurerm_role_assignment.deployer_secrets_officer
  ]
}

# Store SQL connection string in Key Vault
resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "sql-connection-string"
  value        = var.sql_connection_string
  key_vault_id = azurerm_key_vault.this.id
  
  depends_on = [
    azurerm_role_assignment.deployer_secrets_officer
  ]
}

# Store storage account name in Key Vault
resource "azurerm_key_vault_secret" "storage_account_name" {
  name         = "storage-account-name"
  value        = var.storage_account_name
  key_vault_id = azurerm_key_vault.this.id
  
  depends_on = [
    azurerm_role_assignment.deployer_secrets_officer
  ]
}

# RBAC: Grant deployer (Terraform SP) secrets officer access to create secrets
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# RBAC: Grant backend app Key Vault Secrets User (read secrets)
resource "azurerm_role_assignment" "backend_secrets_user" {
  count                = length(var.backend_principal_ids)
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.backend_principal_ids[count.index]
}

# RBAC: Grant frontend app Key Vault Secrets User (read secrets)
resource "azurerm_role_assignment" "frontend_secrets_user" {
  count                = length(var.frontend_principal_ids)
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.frontend_principal_ids[count.index]
}
