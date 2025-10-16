variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "kv_name" {
  type = string
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for private endpoint placement"
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for Key Vault"
}

variable "backend_principal_ids" {
  type        = list(string)
  description = "Managed identity principal IDs for backend apps"
  default     = []
}

variable "frontend_principal_ids" {
  type        = list(string)
  description = "Managed identity principal IDs for frontend apps"
  default     = []
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "SQL admin password to store in Key Vault"
}

variable "sql_connection_string" {
  type        = string
  sensitive   = true
  description = "SQL connection string to store in Key Vault"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name to store in Key Vault"
}
