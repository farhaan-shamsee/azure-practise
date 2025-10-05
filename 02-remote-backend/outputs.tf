output "resource_group_name" {
  description = "Name of the resource group containing the storage account"
  value       = azurerm_resource_group.tfstate_rg.name
}

output "storage_account_name" {
  description = "Name of the storage account for Terraform state"
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Name of the blob container for state files"
  value       = azurerm_storage_container.tfstate.name
}

output "backend_config" {
  description = "Backend configuration for other Terraform projects"
  value = {
    resource_group_name  = azurerm_resource_group.tfstate_rg.name
    storage_account_name = azurerm_storage_account.tfstate.name
    container_name       = azurerm_storage_container.tfstate.name
    key                  = "terraform.tfstate"
  }
}