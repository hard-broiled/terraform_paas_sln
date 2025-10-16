output "key_vault_id" {
  value = azurerm_key_vault.this.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "key_vault_name" {
  value = azurerm_key_vault.this.name
}

output "sql_connection_string_secret_uri" {
  value = azurerm_key_vault_secret.sql_connection_string.id
}

output "storage_account_name_secret_uri" {
  value = azurerm_key_vault_secret.storage_account_name.id
}
