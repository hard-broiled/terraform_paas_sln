variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "sql_server_name" {
  type = string
}

variable "db_name" {
  type = string
}

variable "administrator_login" {
  type    = string
  default = "sqladmin"
}

variable "admin_ad_object_id" {
  type        = string
  description = "Azure AD object ID for SQL administrator"
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for private endpoint placement"
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for SQL Server"
}
