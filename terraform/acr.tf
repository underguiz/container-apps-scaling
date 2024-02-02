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
}

resource "azurerm_role_assignment" "container-apps-acr" {
  scope                = azurerm_container_registry.order-app.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.container-app-identity.principal_id
}