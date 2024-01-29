resource "azurerm_container_app_environment" "order-app" {
  name                       = "order-app"
  location                   = data.azurerm_resource_group.order-app.location
  resource_group_name        = data.azurerm_resource_group.order-app.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.order.id
}

resource "azurerm_container_app" "order-consumer" {
  name                         = "order-consumer"
  container_app_environment_id = azurerm_container_app_environment.order-app.id
  resource_group_name          = data.azurerm_resource_group.order-app.name
  revision_mode                = "Single"

  secret {
    name  = "keda-servicebus-conn-string"
    value = azurerm_servicebus_queue_authorization_rule.consumer-app.primary_connection_string
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [ azurerm_user_assigned_identity.container-app-identity.id ]
  }

  registry {
    server   = azurerm_container_registry.order-app.login_server
    identity = azurerm_user_assigned_identity.container-app-identity.id
  }

  template {
    container {
      name   = "order-consumer"
      image  = "${azurerm_container_registry.order-app.login_server}/order-consumer:v1"
      cpu    = 0.25
      memory = "0.5Gi"
      
      env {
        name  = "HOST_NAME"
        value = "${azurerm_servicebus_namespace.order-app.name}.servicebus.windows.net"
      }
      env {
        name  =  "QUEUE_NAME"
        value = "orders"
      }
      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.container-app-identity.client_id
      }
    }
      
    max_replicas = 20
    min_replicas = 0

    custom_scale_rule {
      name             = "order-app-queue"
      custom_rule_type = "azure-servicebus"
      metadata = {
        queueName    = azurerm_servicebus_queue.orders.name
        messageCount = "50"
      }
      authentication {
        secret_name       = "keda-servicebus-conn-string"
        trigger_parameter = "connection"
      }
    }

  }
}

resource "azurerm_container_app" "order-producer" {
  name                         = "order-producer"
  container_app_environment_id = azurerm_container_app_environment.order-app.id
  resource_group_name          = data.azurerm_resource_group.order-app.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [ azurerm_user_assigned_identity.container-app-identity.id ]
  }

  registry {
    server   = azurerm_container_registry.order-app.login_server
    identity = azurerm_user_assigned_identity.container-app-identity.id
  }

  template {
    container {
      name   = "order-producer"
      image  = "${azurerm_container_registry.order-app.login_server}/order-producer:v1"
      cpu    = 0.25
      memory = "0.5Gi"
      
      env {
        name  = "HOST_NAME"
        value = "${azurerm_servicebus_namespace.order-app.name}.servicebus.windows.net"
      }
      env {
        name =  "QUEUE_NAME"
        value = "orders"
      }
      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.container-app-identity.client_id
      }
    }

  max_replicas = 4
  min_replicas = 4
  
  }
}