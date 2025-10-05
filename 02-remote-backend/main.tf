# Generate a random ID for unique storage account name
resource "random_id" "unique_id" {
  byte_length = 4
}

# Create Resource Group for Terraform state storage
resource "azurerm_resource_group" "tfstate_rg" {
  name     = var.resource_group_name
  location = var.resource_group_location

  tags = {
    Purpose = "TerraformBackend"
    Owner   = "InfraTeam"
  }
}

# Create Storage Account for remote state
resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.tfstate_rg.name
  location                 = azurerm_resource_group.tfstate_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = {
    Purpose = "TerraformBackend"
    Owner   = "InfraTeam"
  }
}

# Create Blob Container for state files
resource "azurerm_storage_container" "tfstate" {
  name                  = "main"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
