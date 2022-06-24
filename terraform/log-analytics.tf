resource "azurerm_log_analytics_workspace" "order" {
  name                = "order-logs"
  location            = data.azurerm_resource_group.order-app.location
  resource_group_name = data.azurerm_resource_group.order-app.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}