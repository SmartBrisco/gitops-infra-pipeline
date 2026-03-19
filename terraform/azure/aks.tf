# --- AKS Subnet ---
resource "azurerm_subnet" "aks" {
  count                = var.deploy ? 1 : 0
  name                 = "gitops-infra-aks-subnet"
  resource_group_name  = azurerm_resource_group.rg[0].name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = ["10.0.2.0/24"]
}

# --- AKS Cluster Identity ---
resource "azurerm_user_assigned_identity" "aks" {
  count               = var.deploy ? 1 : 0
  name                = "gitops-infra-aks-identity"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name
}

# --- AKS Cluster ---
resource "azurerm_kubernetes_cluster" "main" {
  count               = var.deploy ? 1 : 0
  name                = "gitops-infra-aks"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name
  dns_prefix          = "gitops-infra-aks"
  kubernetes_version  = "1.31"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_D2_v2" # Demo only — production minimum Standard_D4_v2
    vnet_subnet_id = azurerm_subnet.aks[0].id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks[0].id]
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  tags = {
    managed-by  = "terraform"
    environment = "dev"
  }
}