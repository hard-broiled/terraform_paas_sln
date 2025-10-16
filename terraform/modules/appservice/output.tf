output "app_principal_ids" {
  value = { for k, v in azurerm_linux_web_app.apps : k => v.identity[0].principal_id }
}

output "app_names" {
  value = { for k, v in azurerm_linux_web_app.apps : k => v.name }
}

output "app_ids" {
  value = { for k, v in azurerm_linux_web_app.apps : k => v.id }
}

output "frontend_url" {
  value = try(azurerm_linux_web_app.apps["frontend"].default_hostname, "")
}

output "backend_url" {
  value = try(azurerm_linux_web_app.apps["backend"].default_hostname, "")
}

output "app_outbound_ips" {
  value = { for k, v in azurerm_linux_web_app.apps : k => v.outbound_ip_addresses }
}
