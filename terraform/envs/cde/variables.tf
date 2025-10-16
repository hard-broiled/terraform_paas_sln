variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region for resources"
}

variable "rg_name" {
  type        = string
  default     = "rg-myapp-cde"
  description = "Resource group name"
}

variable "env_short" {
  type        = string
  default     = "cde"
  description = "Short environment name used in resource naming"
}

variable "admin_ad_object_id" {
  type        = string
  description = "Azure AD object ID for initial SQL admin (user or service principal)"
}
