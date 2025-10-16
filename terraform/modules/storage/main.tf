resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  
  # Disable public access - force private endpoint
  public_network_access_enabled = false
  
  # Enable secure transfer
  # enable_https_traffic_only = true
  
  # Disable shared key access (optional - forces Azure AD auth only)
  # shared_access_key_enabled = false
  
  # Enable blob versioning and soft delete for data protection
  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "containers" {
  for_each              = toset(var.container_names)
  name                  = each.key
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

# Private endpoint for blob storage
resource "azurerm_private_endpoint" "blob_pe" {
  name                = "${var.storage_account_name}-blob-pe"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.storage_account_name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

# Grant App Service managed identities blob access using RBAC
# Storage Blob Data Contributor role for backend app (read/write)
resource "azurerm_role_assignment" "backend_blob_contributor" {
  count                = length(var.backend_principal_ids)
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.backend_principal_ids[count.index]
}

# Storage Blob Data Reader role for frontend app (read-only)
resource "azurerm_role_assignment" "frontend_blob_reader" {
  count                = length(var.frontend_principal_ids)
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.frontend_principal_ids[count.index]
}
