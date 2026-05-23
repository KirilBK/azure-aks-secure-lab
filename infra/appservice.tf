resource "azurerm_service_plan" "asp" {
  name                = "ASP-LINUX"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1" # B1 supports always-on/HTTPS niceties; F1 also allowed by the exam
  tags                = local.common_tags
}

locals {
  kv_ref = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sql_conn.versionless_id})"
}

resource "azurerm_linux_web_app" "app2" {
  name                = "app2-${local.suffix}-securelab"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
    application_stack {
      php_version = "8.3"
    }
  }

  app_settings = {
    SQL_CONNECTION_STRING = local.kv_ref
  }
}

resource "azurerm_linux_web_app" "app3" {
  name                = "app3-${local.suffix}-securelab"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id
  https_only          = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
    application_stack {
      php_version = "8.3"
    }
  }

  app_settings = {
    SQL_CONNECTION_STRING = local.kv_ref
  }
}
