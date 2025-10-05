terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.46.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  # Note: This configuration uses local state
  # This is intentional as it creates the backend infrastructure
}

provider "azurerm" {
  features {}
}