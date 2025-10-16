output "rg_name" {
  value = azurerm_resource_group.this.name
}

output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  value = { for k, s in azurerm_subnet.subnets : k => s.id }
}

output "private_dns_zone_ids" {
  value = { for k, z in azurerm_private_dns_zone.zones : k => z.id }
}
