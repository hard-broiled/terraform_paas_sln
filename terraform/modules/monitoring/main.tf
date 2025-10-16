resource "azurerm_log_analytics_workspace" "this" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    created_by = "terraform"
  }
}

resource "azurerm_application_insights" "this" {
  name                = "${var.workspace_name}-appinsights"
  location            = var.location
  resource_group_name = var.rg_name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"

  tags = {
    created_by = "terraform"
  }
}

# Diagnostic settings for SQL Database
resource "azurerm_monitor_diagnostic_setting" "sql_diag" {
  count                      = var.sql_database_id != "" ? 1 : 0
  name                       = "sql-diagnostics"
  target_resource_id         = var.sql_database_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "SQLInsights"
  }

  enabled_log {
    category = "AutomaticTuning"
  }

  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }

  enabled_log {
    category = "Errors"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Diagnostic settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage_diag" {
  count                      = var.storage_account_id != "" ? 1 : 0
  name                       = "storage-diagnostics"
  target_resource_id         = var.storage_account_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_metric {
    category = "AllMetrics"
  }
}

# Diagnostic settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "kv_diag" {
  count                      = var.key_vault_id != "" ? 1 : 0
  name                       = "kv-diagnostics"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
