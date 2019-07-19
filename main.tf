provider "azurerm" {
  version = "=1.31.0"
}

provider "azuread" {
  version = "=0.4.0"
}

data "azurerm_client_config" "current" {}


resource "azurerm_resource_group" "main" {
  name     = "nw-web-app-test-rg"
  location = "West Europe"
}

resource "azurerm_app_service_plan" "main" {
  name                = "nw-web-app-test-sp"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "main" {
  name                = "${local.name}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  app_service_plan_id = "${azurerm_app_service_plan.main.id}"

  auth_settings {
    enabled = true
    active_directory {
      client_id     = "${azuread_application.main.application_id}"
      client_secret = "${random_string.password.result}"

      allowed_audiences = [
        "${local.auth_hostname}"
      ]
    }

    issuer              = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/"
    default_provider    = "AzureActiveDirectory"
    token_store_enabled = true
  }

  app_settings = {
    "Some test"   = "Lets change this value"
    "Some test12" = "Lets change this value"
  }
}

resource "azuread_application" "main" {
  name                       = "nw-web-app-test"
  homepage                   = "${local.full_hostname}"
  identifier_uris            = ["${local.full_hostname}"]
  reply_urls                 = ["${local.auth_hostname}"]
  available_to_other_tenants = false
  oauth2_allow_implicit_flow = true
  type                       = "webapp/api"
}

resource "azuread_application_password" "example" {
  application_id    = "${azuread_application.main.id}"
  value             = "${random_string.password.result}"
  end_date_relative = "17520h"
}

resource "random_string" "password" {
  length  = 32
  special = true
}

locals {
  name          = "nw-web-app-test-web"
  hostname      = "${local.name}.azurewebsites.net"
  full_hostname = "https://${local.hostname}/"
  auth_hostname = "${local.full_hostname}.auth/login/aad/callback"
}