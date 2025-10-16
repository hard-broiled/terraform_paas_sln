variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "workspace_name" {
  type = string
}

variable "sql_database_id" {
  type        = string
  description = "SQL Database ID for diagnostic settings"
  default     = ""
}

variable "storage_account_id" {
  type        = string
  description = "Storage Account ID for diagnostic settings"
  default     = ""
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault ID for diagnostic settings"
  default     = ""
}
