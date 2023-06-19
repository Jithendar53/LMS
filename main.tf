terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.35.0"
    }
  }
}

provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "Ansible" {
  name     = "Ansible"
  location = "eastus"
  tags = {
    "env" = "prod1"
    "app" = "cts"
  }
}

resource "azurerm_virtual_network" "Ansible-net1" {

  name                = "Ansible-net1"
  resource_group_name = azurerm_resource_group.Ansible.name
  location            = azurerm_resource_group.Ansible.location
  address_space       = ["99.99.0.0/24"]
}

resource "azurerm_subnet" "Ansible-s1" {
  name                = "Ansible-s1"
  resource_group_name = azurerm_resource_group.Ansible.name
  # location             = azurerm_resource_group.Ansible.location
  address_prefixes     = ["99.99.0.0/25"]
  virtual_network_name = azurerm_virtual_network.Ansible-net1.name

}
resource "azurerm_subnet" "Ansible-s2" {
  name                = "Ansible-s2"
  resource_group_name = azurerm_resource_group.Ansible.name
  # location            = azurerm_resource_group.Ansible.location
  address_prefixes     = ["99.99.0.128/25"]
  virtual_network_name = azurerm_virtual_network.Ansible-net1.name
}

resource "azurerm_public_ip" "Ansible-pip" {
  count = 3
  name                = "Ansible-public-ip-${count.index}"
  location            = azurerm_resource_group.Ansible.location
  resource_group_name = azurerm_resource_group.Ansible.name
  allocation_method   = "Dynamic"

}

resource "azurerm_network_interface" "vm-nic" {
  count = 3
  name                = "vm-nic-${count.index}"
  resource_group_name = azurerm_resource_group.Ansible.name
  location            = azurerm_resource_group.Ansible.location
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.Ansible-s1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Ansible-pip[count.index].id

  }

}
resource "azurerm_linux_virtual_machine" "vm1" {
  count = 3
  name                            = "vm-${count.index}"
  resource_group_name             = azurerm_resource_group.Ansible.name
  location                        = azurerm_resource_group.Ansible.location
  size                            = "Standard_B1s"
  admin_username                  = "ansible"
  admin_password                  = "Jithendar@7172"
 

  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.vm-nic[count.index].id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  boot_diagnostics {
    storage_account_uri = ""  
}
}