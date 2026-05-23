output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_database_name" {
  value = azurerm_mssql_database.db.name
}

output "app1_workload_identity_client_id" {
  description = "Stamp this into the app1 ServiceAccount annotation."
  value       = azurerm_user_assigned_identity.app1.client_id
}

output "key_vault_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "app2_default_hostname" {
  value = "https://${azurerm_linux_web_app.app2.default_hostname}"
}

output "app3_default_hostname" {
  value = "https://${azurerm_linux_web_app.app3.default_hostname}"
}

output "function_app_name" {
  value = azurerm_linux_function_app.func.name
}

# WARNING: sensitive — exposed only so you can seed the schema once. Pull it
# from Key Vault in real workflows instead of reading this output.
output "sql_admin_password" {
  value     = random_password.sql.result
  sensitive = true
}
