resource "azurerm_storage_account" "func" {
  name                            = "st${local.suffix}funcsecure"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS" # Student subs disallow geo-redundant
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = local.common_tags
}

resource "azurerm_linux_function_app" "func" {
  name                       = "func-${local.suffix}-securelab"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  service_plan_id            = azurerm_service_plan.asp.id   # was azurerm_service_plan.func.id
  storage_account_name       = azurerm_storage_account.func.name
  storage_account_access_key = azurerm_storage_account.func.primary_access_key
  https_only                 = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
    always_on           = true                               # required on a dedicated plan (keeps the timer alive)
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    SQL_CONNECTION_STRING          = local.kv_ref
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"                  # builds Python deps on publish
    ENABLE_ORYX_BUILD              = "true"                  # avoids the SCM timeout you hit
  }
}
