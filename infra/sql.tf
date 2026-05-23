resource "azurerm_mssql_server" "sql" {
  name                          = "sql-${local.suffix}-securelab"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = random_password.sql.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true

  azuread_administrator {
    login_username = "aad-sql-admin"
    object_id      = data.azurerm_client_config.current.object_id
    tenant_id      = data.azurerm_client_config.current.tenant_id
  }

  tags = local.common_tags
}

resource "azurerm_mssql_database" "db" {
  name      = "kirilbkdb"
  server_id = azurerm_mssql_server.sql.id

  sku_name                    = "GP_S_Gen5_1"
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60
  max_size_gb                 = 2
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  zone_redundant              = false
  tags = local.common_tags
}


resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0" # the 0.0.0.0/0.0.0.0 special-case = "Azure services only"
}


resource "azurerm_mssql_firewall_rule" "allow_me" {
  name             = "AllowOperatorIP"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = var.my_ip_address
  end_ip_address   = var.my_ip_address
}
