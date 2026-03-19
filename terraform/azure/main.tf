resource "azurerm_resource_group" "rg" {
  count    = var.deploy ? 1 : 0
  name     = var.resource_group_name
  location = var.location

  tags = {
    managed-by  = "terraform"
    environment = "dev"
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
    environment = "dev"
  }
}