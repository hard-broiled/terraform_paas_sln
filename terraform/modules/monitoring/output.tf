output "workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "appinsights_connection_string" {
  value     = azurerm_application_insights.this.connection_string
  sensitive = true
}

output "appinsights_instrumentation_key" {
  value     = azurerm_application_insights.this.instrumentation_key
  sensitive = true
}

output "appinsights_app_id" {
  value = azurerm_application_insights.this.app_id
}
