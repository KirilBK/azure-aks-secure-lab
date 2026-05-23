resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.resource_group_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-secure-lab"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  dns_prefix          = "akssecurelab"

  sku_tier = "Free"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  local_account_disabled    = true # force Entra-backed kubeconfig, no static admin

  default_node_pool {
    name                 = "system"
    node_count           = var.aks_node_count
    vm_size              = var.aks_node_size
    os_disk_size_gb      = 32
    only_critical_addons_enabled = false
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }

  tags = local.common_tags
}

resource "azurerm_role_assignment" "aks_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}
