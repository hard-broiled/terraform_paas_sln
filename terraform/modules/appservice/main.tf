resource "azurerm_service_plan" "plan" {
  name                = var.plan_name
  location            = var.location
  resource_group_name = var.rg_name
  os_type             = "Linux"
  sku_name            = var.sku
}

resource "azurerm_linux_web_app" "apps" {
  for_each            = toset(var.webapps)
  name                = "${each.key}-${substr(replace(var.rg_name, "/", "-"), 0, 12)}"
  location            = var.location
  resource_group_name = var.rg_name
  service_plan_id     = azurerm_service_plan.plan.id

  # Enable system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  site_config {
    linux_fx_version = "" # Set via deployment (e.g., "NODE|18-lts")
    ftps_state       = "Disabled"
    always_on        = true
    
    # Security headers
    http2_enabled                      = true
    minimum_tls_version                = "1.2"
    scm_minimum_tls_version            = "1.2"
    remote_debugging_enabled           = false
    use_32_bit_worker                  = false
    vnet_route_all_enabled             = true  # Force all outbound through VNet
    
    # CORS configuration (adjust as needed)
    cors {
      allowed_origins = var.cors_allowed_origins
      support_credentials = false
    }
  }

  # HTTPS only
  https_only = true

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"       = "1"
    "WEBSITE_TIME_ZONE"              = "UTC"
    "WEBSITE_DISABLE_MSI"            = "0"
    "WEBSITE_VNET_ROUTE_ALL"         = "1"
    
    # Key Vault references (apps will read secrets from KV using managed identity)
    "SQL_CONNECTION_STRING"          = var.sql_connection_string_ref
    "STORAGE_ACCOUNT_NAME"           = var.storage_account_name_ref
    
    # Application Insights (if monitoring module provides key)
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.appinsights_connection_string
  }

  lifecycle {
    ignore_changes = [
      app_settings,  # Allow app-level config changes
      tags
    ]
  }
}

# VNet integration for all apps
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  for_each       = azurerm_linux_web_app.apps
  app_service_id = each.value.id
  subnet_id      = var.vnet_subnet_id
}

# Access restrictions for backend app (private only - only accessible from VNet)
resource "azurerm_linux_web_app" "backend_private" {
  for_each            = { for k in var.webapps : k => k if k == "backend" }
  name                = "${each.key}-private-${substr(replace(var.rg_name, "/", "-"), 0, 12)}"
  location            = var.location
  resource_group_name = var.rg_name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    linux_fx_version = "" # Set as needed
    ftps_state       = "Disabled"
    always_on        = true
    http2_enabled    = true
    minimum_tls_version = "1.2"
    scm_minimum_tls_version = "1.2"
    remote_debugging_enabled = false
    use_32_bit_worker = false
    vnet_route_all_enabled = true
    cors {
      allowed_origins = var.cors_allowed_origins
      support_credentials = false
    }
    # Add ip_restriction or other backend-specific settings here if needed
  }

  https_only = true

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"       = "1"
    "WEBSITE_TIME_ZONE"              = "UTC"
    "WEBSITE_DISABLE_MSI"            = "0"
    "WEBSITE_VNET_ROUTE_ALL"         = "1"
    "SQL_CONNECTION_STRING"          = var.sql_connection_string_ref
    "STORAGE_ACCOUNT_NAME"           = var.storage_account_name_ref
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.appinsights_connection_string
  }

  depends_on = [azurerm_linux_web_app.apps]
}

# Private endpoint for backend app (makes it accessible only via private IP)
resource "azurerm_private_endpoint" "backend_pe" {
  count               = contains(var.webapps, "backend") ? 1 : 0
  name                = "backend-${substr(replace(var.rg_name, "/", "-"), 0, 12)}-pe"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "backend-psc"
    private_connection_resource_id = azurerm_linux_web_app.apps["backend"].id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "backend-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}