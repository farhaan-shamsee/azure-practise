variable "resource_group_name" {
  type        = string
  default     = "prod-networking-rg"
  description = "Name for the Azure resource group"
}

variable "resource_group_location" {
  type        = string
  default     = "East US"
  description = "Azure region"
}

variable "vnet_name" {
  description = "The name of the Virtual Network"
  type        = string
  default     = "myVNet"
}

variable "vnet_address_space" {
  description = "The address space for the Virtual Network"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "vm_name" {
  default = "nginx-web"
}

variable "admin_username" {
  default = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "SSH public key for VM login"
  type        = string
  default = ""
}

variable "my_public_ip"{
  description = "Your local machine public IP address"
  type        = string
  default = "192.168.0.1"
}