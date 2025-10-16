variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "plan_name" {
  type = string
}

variable "sku" {
  type    = string
  default = "S1"
}

variable "webapps" {
  type        = list(string)
  description = "List of web apps to create (e.g., ['frontend', 'backend'])"
}

variable "vnet_subnet_id" {
  type        = string
  description = "Subnet ID for VNet integration"
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for private endpoint (backend app)"
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for App Service"
}

variable "cors_allowed_origins" {
  type        = list(string)
  description = "Allowed CORS origins"
  default     = []
}

variable "sql_connection_string_ref" {
  type        = string
  description = "Key Vault reference for SQL connection string"
  default     = ""
}

variable "storage_account_name_ref" {
  type        = string
  description = "Key Vault reference for storage account name"
  default     = ""
}

variable "appinsights_connection_string" {
  type        = string
  description = "Application Insights connection string"
  default     = ""
}
