resource "azurerm_virtual_network" "vnet" {
  count               = var.deploy ? 1 : 0
  name                = "gitops-infra-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name

  tags = {
    managed-by  = "terraform"
    environment = "dev"
  }
}

resource "azurerm_subnet" "subnet" {
  count                = var.deploy ? 1 : 0
  name                 = "gitops-infra-subnet"
  resource_group_name  = azurerm_resource_group.rg[0].name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  count               = var.deploy ? 1 : 0
  name                = "gitops-infra-nsg"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    managed-by  = "terraform"
    environment = "dev"
  }
}

resource "azurerm_network_interface" "nic" {
  count               = var.deploy ? 1 : 0
  name                = "gitops-infra-nic"
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet[0].id
    private_ip_address_allocation = "Dynamic"
  }
}