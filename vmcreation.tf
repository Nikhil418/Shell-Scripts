terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "myrg" {
  name     = "Nikhil-RG"
  location = "eastus"
}

resource "azurerm_virtual_network" "myvnet" {
  name                = "vnet1"
  address_space       = ["172.10.2.0/24"]
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
}

resource "azurerm_subnet" "mysubnet" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.myrg.name
  virtual_network_name = azurerm_virtual_network.myvnet.name
  address_prefixes     = ["172.10.2.0/26"]  # Use a list for address_prefixes
}

resource "azurerm_network_security_group" "sg" {
  count               = 3
  name                = "example-nsg-${count.index}"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "mypubip" {
  count                = 3
  name                 = "example-publicip-${count.index}"
  location             = azurerm_resource_group.myrg.location
  resource_group_name  = azurerm_resource_group.myrg.name
  allocation_method    = "Dynamic"
}

resource "azurerm_network_interface" "mynic" {
  count               = 3
  name                = "example-nic-${count.index}"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name

  ip_configuration {
    name                          = "myNICConfig"
    subnet_id                     = element(azurerm_subnet.mysubnet.*.id, count.index)
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id           = element(azurerm_public_ip.mypubip.*.id, count.index)
  }
}

resource "azurerm_linux_virtual_machine" "myvm" {
  count                 = 3
  name                  = "example-vm-${count.index}"
  location              = azurerm_resource_group.myrg.location
  resource_group_name   = azurerm_resource_group.myrg.name
  network_interface_ids = [azurerm_network_interface.mynic[count.index].id]
  size                  = "Standard_B1s"
  disable_password_authentication = false
  admin_username        = "nik"
  admin_password        = "Nikhil@#1611"  # Change this to your desired password or use SSH keys

  os_disk {
    name              = "example-osdisk-${count.index}"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
