output "sql_server_name" {
  value = azurerm_mssql_server.this.name
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "db_name" {
  value = azurerm_mssql_database.db.name
}

output "sql_server_id" {
  value = azurerm_mssql_server.this.id
}

output "connection_string" {
  value     = "Server=tcp:${azurerm_mssql_server.this.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.db.name};Authentication=Active Directory Default;"
  sensitive = true
}

output "admin_password" {
  value     = random_password.sql_admin_pw.result
  sensitive = true
}
