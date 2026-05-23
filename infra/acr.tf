resource "azurerm_container_registry" "acr" {
  name                = "acr${local.suffix}securelab"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = merge(local.common_tags, {
    purpose = "project"
  })
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = azurerm_container_registry.acr.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_management_lock" "acr_lock" {
  name       = "Project-Lock"
  scope      = azurerm_container_registry.acr.id
  lock_level = "CanNotDelete"
  notes      = "Prevents accidental deletion of the registry (exam requirement)."
}
