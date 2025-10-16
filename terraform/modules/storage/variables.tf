variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "container_names" {
  type    = list(string)
  default = ["static-assets"]
}

variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for private endpoint placement"
}

variable "private_dns_zone_id" {
  type        = string
  description = "Private DNS zone ID for blob storage"
}

variable "backend_principal_ids" {
  type        = list(string)
  description = "Managed identity principal IDs for backend apps (read/write access)"
  default     = []
}

variable "frontend_principal_ids" {
  type        = list(string)
  description = "Managed identity principal IDs for frontend apps (read-only access)"
  default     = []
}
