# Production Environment - Same structure as CDE with prod-specific configuration

# 1. Network foundation
module "network" {
  source   = "../../modules/network"
  location = var.location
  rg_name  = var.rg_name
  vnet_name = "myapp-vnet-${var.env_short}"
}

# 2. Monitoring
module "monitoring" {
  source         = "../../modules/monitoring"
  location       = var.location
  rg_name        = var.rg_name
  workspace_name = "law-${var.env_short}-myapp"
}

# 3. SQL Database
module "sql" {
  source           = "../../modules/sql"
  location         = var.location
  rg_name          = var.rg_name
  sql_server_name  = "sql-myapp-${var.env_short}"
  db_name          = "appdb"
  admin_ad_object_id = var.admin_ad_object_id
  
  private_endpoint_subnet_id = module.network.subnet_ids["privateendpoint"]
  private_dns_zone_id        = module.network.private_dns_zone_ids["sql"]
  
  depends_on = [module.network]
}

# 4. App Services
module "appservice" {
  source         = "../../modules/appservice"
  location       = var.location
  rg_name        = var.rg_name
  plan_name      = "asp-${var.env_short}-myapp"
  sku            = "P1v2"  # Production uses Premium tier
  webapps        = ["frontend", "backend"]
  vnet_subnet_id = module.network.subnet_ids["app"]
  
  private_endpoint_subnet_id = module.network.subnet_ids["privateendpoint"]
  private_dns_zone_id        = module.network.private_dns_zone_ids["web"]
  
  sql_connection_string_ref      = "@Microsoft.KeyVault(SecretUri=${module.keyvault.sql_connection_string_secret_uri})"
  storage_account_name_ref       = "@Microsoft.KeyVault(SecretUri=${module.keyvault.storage_account_name_secret_uri})"
  appinsights_connection_string  = module.monitoring.appinsights_connection_string
  
  depends_on = [module.network, module.keyvault]
}

# 5. Storage Account
module "storage" {
  source               = "../../modules/storage"
  location             = var.location
  rg_name              = var.rg_name
  storage_account_name = "stmyapp${var.env_short}01"
  container_names      = ["static-assets"]
  
  private_endpoint_subnet_id = module.network.subnet_ids["privateendpoint"]
  private_dns_zone_id        = module.network.private_dns_zone_ids["blob"]
  
  backend_principal_ids  = [module.appservice.app_principal_ids["backend"]]
  frontend_principal_ids = [module.appservice.app_principal_ids["frontend"]]
  
  depends_on = [module.network, module.appservice]
}

# 6. Key Vault
module "keyvault" {
  source  = "../../modules/keyvault"
  location = var.location
  rg_name = var.rg_name
  kv_name = "kv-${var.env_short}-myapp"
  
  private_endpoint_subnet_id = module.network.subnet_ids["privateendpoint"]
  private_dns_zone_id        = module.network.private_dns_zone_ids["kv"]
  
  backend_principal_ids  = [module.appservice.app_principal_ids["backend"]]
  frontend_principal_ids = [module.appservice.app_principal_ids["frontend"]]
  
  sql_admin_password     = module.sql.admin_password
  sql_connection_string  = module.sql.connection_string
  storage_account_name   = module.storage.storage_account_name
  
  depends_on = [module.network, module.appservice, module.sql, module.storage]
}

# 7. Diagnostics
module "monitoring_diagnostics" {
  source         = "../../modules/monitoring"
  location       = var.location
  rg_name        = var.rg_name
  workspace_name = "law-${var.env_short}-myapp"
  
  sql_database_id     = module.sql.sql_server_id
  storage_account_id  = module.storage.storage_account_id
  key_vault_id        = module.keyvault.key_vault_id
  
  depends_on = [
    module.sql,
    module.storage,
    module.keyvault
  ]
}

# Outputs
output "frontend_url" {
  value       = "https://${module.appservice.frontend_url}"
  description = "Frontend application URL (public)"
}

output "backend_url" {
  value       = module.appservice.backend_url
  description = "Backend application URL (private)"
}

output "resource_group_name" {
  value = var.rg_name
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "sql_server_fqdn" {
  value = module.sql.sql_server_fqdn
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}
