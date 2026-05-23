resource "random_password" "sql" {
  length           = 24
  special          = true
  override_special = "!#%*-_"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
}

resource "azurerm_key_vault" "kv" {
  name                       = "kv-${local.suffix}-securelab"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  enable_rbac_authorization  = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = local.common_tags
}

resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "sql_conn" {
  name  = "sql-connection-string"
  value = "Server=tcp:${azurerm_mssql_server.sql.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.db.name};User ID=${var.sql_admin_login};Password=${random_password.sql.result};Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"

  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_admin]
}


resource "azurerm_role_assignment" "kv_app1" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app1.principal_id
}

resource "azurerm_role_assignment" "kv_app2" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.app2.identity[0].principal_id
}

resource "azurerm_role_assignment" "kv_app3" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.app3.identity[0].principal_id
}

resource "azurerm_role_assignment" "kv_func" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.func.identity[0].principal_id
}
