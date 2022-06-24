resource "azapi_resource" "order-app" {
  type      = "Microsoft.App/managedEnvironments@2022-03-01"
  name      = "order-app"
  parent_id = data.azurerm_resource_group.order-app.id
  location  = data.azurerm_resource_group.order-app.location
  body = jsonencode({
    properties = {
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = azurerm_log_analytics_workspace.order.workspace_id
          sharedKey  = azurerm_log_analytics_workspace.order.primary_shared_key
        }
      }
    }
  })

  ignore_missing_property = true
}

resource "azapi_resource" "order-consumer" {
  type      = "Microsoft.App/containerApps@2022-03-01"
  name      = "order-consumer"
  parent_id = data.azurerm_resource_group.order-app.id
  location  = data.azurerm_resource_group.order-app.location
  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.order-app.id
      configuration = {
        secrets = [
          {
            name  = "registry-password"
            value = azurerm_container_registry.order-app.admin_password
          },
          {
            name  = "service-bus-conn-string"
            value = azurerm_servicebus_queue_authorization_rule.consumer-app.primary_connection_string
          }
        ]
        registries = [
          {
            passwordSecretRef = "registry-password"
            server            = azurerm_container_registry.order-app.login_server
            username          = azurerm_container_registry.order-app.admin_username
          }
        ]
      }
      template = {
        containers = [
          {
            image = "${azurerm_container_registry.order-app.login_server}/order-consumer:v1",
            name  = "order-consumer"
            env   = [
              {
                name      = "CONNECTION_STR"
                secretRef = "service-bus-conn-string"
              },
              {
                name      = "QUEUE_NAME"
                value     = azurerm_servicebus_queue.orders.name
              }
            ]
          }
        ]
        scale = {
          maxReplicas = 20
          minReplicas = 0
          rules = [ 
            {
              name   = "order-app-queue"
              custom = {
                type     = "azure-servicebus"
                metadata = {
                  queueName    = azurerm_servicebus_queue.orders.name
                  messageCount = "50"
                }
                auth = [
                  {
                    secretRef        = "service-bus-conn-string"
                    triggerParameter = "connection"
                  }
                ]
              }
            } 
          ] 
        }
      }
    }
  })

  ignore_missing_property = true

}

resource "azapi_resource" "order-producer" {
  type      = "Microsoft.App/containerApps@2022-03-01"
  name      = "order-producer"
  parent_id = data.azurerm_resource_group.order-app.id
  location  = data.azurerm_resource_group.order-app.location
  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.order-app.id
      configuration = {
        secrets = [
          {
            name  = "registry-password"
            value = azurerm_container_registry.order-app.admin_password
          },
          {
            name  = "service-bus-conn-string"
            value = azurerm_servicebus_queue_authorization_rule.consumer-app.primary_connection_string
          }
        ]
        registries = [
          {
            passwordSecretRef = "registry-password"
            server            = azurerm_container_registry.order-app.login_server
            username          = azurerm_container_registry.order-app.admin_username
          }
        ]
      }
      template = {
        containers = [
          {
            image = "${azurerm_container_registry.order-app.login_server}/order-producer:v1",
            name  = "order-producer"
            env   = [
              {
                name      = "CONNECTION_STR"
                secretRef = "service-bus-conn-string"
              },
              {
                name      = "QUEUE_NAME"
                value     = azurerm_servicebus_queue.orders.name
              }
            ]
          }
        ]
        scale = {
          maxReplicas = 4
          minReplicas = 4
        }
      }
    }
  })

  ignore_missing_property = true

}