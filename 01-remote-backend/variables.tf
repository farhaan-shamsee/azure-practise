variable "resource_group_name" {
  type        = string
  default     = "prod-networking-rg"
  description = "Name for the Azure resource group"
}
variable "resource_group_location" {
  type        = string
  default     = "East US"
  description = "Azure region for the resource group"
}
variable "storage_account_name" {
  type        = string
  description = "Name for the storage account (must be globally unique, 3-24 characters, lowercase letters and numbers only)"
  
}