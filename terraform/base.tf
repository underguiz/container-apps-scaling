terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {
}

variable "order-app" {
  type    = string
  default = "order-app"
}

data "azurerm_resource_group" "order-app" {
    name = var.order-app
}