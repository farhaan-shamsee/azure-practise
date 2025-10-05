terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.46.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "terraform-backend-rg"
    storage_account_name = "farrowmainbackend"
    container_name       = "main"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
