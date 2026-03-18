resource "azurerm_resource_group" "rg" {
  count    = var.deploy ? 1 : 0
  name     = var.resource_group_name
  location = var.location

  tags = {
    managed-by  = "terraform"
    environment = "demo"
  }
}

resource "azurerm_virtual_network" "vnet" {
  count               = var.deploy ? 1 : 0
  name                = "gitops-infra-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg[0].location
  resource_group_name = azurerm_resource_group.rg[0].name

  tags = {
    managed-by  = "terraform"
    environment = "demo"
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
    environment = "demo"
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

resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.deploy ? 1 : 0
  name                = "gitops-infra-vm"
  resource_group_name = azurerm_resource_group.rg[0].name
  location            = azurerm_resource_group.rg[0].location
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.nic[0].id
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = var.ssh_public_key != "" ? var.ssh_public_key : "placeholder-key-replace-when-deploying"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    managed-by  = "terraform"
    environment = "demo"
  }
}
