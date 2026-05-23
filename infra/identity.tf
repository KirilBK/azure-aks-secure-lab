resource "azurerm_user_assigned_identity" "app1" {
  name                = "id-app1-workload"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.common_tags
}

resource "azurerm_federated_identity_credential" "app1" {
  name                = "fic-app1"
  resource_group_name = azurerm_resource_group.rg.name
  parent_id           = azurerm_user_assigned_identity.app1.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:app1:app1-sa"
}
