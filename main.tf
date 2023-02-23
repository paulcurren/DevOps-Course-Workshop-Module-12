terraform {
 required_providers {
 azurerm = {
  source = "hashicorp/azurerm"
  version = ">= 3.8"
  }
 }
}

provider "azurerm" {
 features {}
}

# azure resource group
data "azurerm_resource_group" "main" {
 name = "Cohort22_PauCur_ProjectExercise"
}

# app service plan
resource "azurerm_service_plan" "main" {
  name                = "terraformed-asp"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# azure webapp
resource "azurerm_linux_web_app" "main" {
  name                = "app-module12-pdc"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    application_stack {
      docker_image     = "paulcurren/todo-app"
      docker_image_tag = "prod"
    }
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL" = "https://index.docker.io"
    "FLASK_APP"                  = "todo_app/app:create_app()"
    "FLASK_ENV"                  = "production"
    "SECRET_KEY"                 = "secret-key"

    "MONGODB_CONNECTION_STRING"  = resource.azurerm_cosmosdb_account.main.connection_strings[0]

    "CLIENT_ID"                  = "159b46be20b7f95bf0f7"
    "CLIENT_SECRET"              = "3259e84f89ffd78a56ff4277f16d8ae271e98870"

    "HOME_URI"                   = "https://app-module12-pdc.azurewebsites.net/"
    "OAUTH_URI"                  = "https://app-module12-pdc.azurewebsites.net/login/callback"
  }
}

# database account
resource "azurerm_cosmosdb_account" "main" {
  name                = "dbaccount-module12-pdc"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  geo_location {
    location          = data.azurerm_resource_group.main.location
    failover_priority = 0
  }

  capabilities {
      name = "EnableServerless"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }
}


# database
resource "azurerm_cosmosdb_mongo_database" "main" {
  name                = "dbaccount-module12-pdc"
  resource_group_name = data.azurerm_resource_group.main.name
  account_name        = resource.azurerm_cosmosdb_account.main.name
}


