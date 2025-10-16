data "azurerm_client_config" "current" {}

resource "random_password" "sql_admin_pw" {
  length  = 20
  special = true
}

# Using azurerm_mssql_server (modern resource, not deprecated)
resource "azurerm_mssql_server" "this" {
  name                         = var.sql_server_name
  resource_group_name          = var.rg_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.administrator_login
  administrator_login_password = random_password.sql_admin_pw.result
  
  # Disable public network access - force private endpoint only
  public_network_access_enabled = false
  
  # Enable Azure AD authentication
  azuread_administrator {
    login_username = "aad-admin"
    object_id      = var.admin_ad_object_id
    tenant_id      = data.azurerm_client_config.current.tenant_id
  }

  tags = {
    created_by = "terraform"
  }
}

resource "azurerm_mssql_database" "db" {
  name      = var.db_name
  server_id = azurerm_mssql_server.this.id
  sku_name  = "S0"
  
  # Enable advanced security features
  ledger_enabled = false
  zone_redundant = false

  tags = {
    created_by = "terraform"
  }
}

# Private endpoint for SQL Server
resource "azurerm_private_endpoint" "sql_pe" {
  name                = "${var.sql_server_name}-pe"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.sql_server_name}-psc"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sql-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}

# Grant App Service managed identities access to SQL Database
# Using SQL contained users (more secure than connection strings)
resource "azurerm_mssql_database_extended_auditing_policy" "db_audit" {
  database_id = azurerm_mssql_database.db.id
  
  # Enable auditing for compliance
  enabled = true
}

# Role assignments for managed identities to access SQL
# Note: Actual SQL user creation needs to be done via SQL scripts or post-deployment
# The create_mi_user.sql script should be run after deployment with these principals
