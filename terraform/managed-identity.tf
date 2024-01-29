resource "azurerm_user_assigned_identity" "container-app-identity" {
  name                = "container-app-identity"
  location            = data.azurerm_resource_group.order-app.location
  resource_group_name = data.azurerm_resource_group.order-app.name
}

resource "azurerm_role_assignment" "order-app" {
  scope                = azurerm_servicebus_queue.orders.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = azurerm_user_assigned_identity.container-app-identity.principal_id
}