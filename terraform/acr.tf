resource "random_string" "acr" {
  length           = 6
  special          = false
  upper            = false
}

resource "azurerm_container_registry" "order-app" {
  name                = "orderapp${random_string.acr.result}"
  resource_group_name = data.azurerm_resource_group.order-app.name
  location            = data.azurerm_resource_group.order-app.location
  sku                 = "Standard"
  admin_enabled       = true
}