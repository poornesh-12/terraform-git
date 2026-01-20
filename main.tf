terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "poornesh_rg" {
  name     = "poornesh-rg-us"
  location = "australiaeast"
}

# Virtual Network
resource "azurerm_virtual_network" "poornesh_vnet_tf" {
  name                = "poornesh-vnet-tf"
  address_space       = ["10.0.0.0/16"]
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.poornesh_rg.name
}

# Subnet
resource "azurerm_subnet" "poornesh_subnet_tf" {
  name                 = "poornesh-subnet-tf"
  resource_group_name  = azurerm_resource_group.poornesh_rg.name
  virtual_network_name = azurerm_virtual_network.poornesh_vnet_tf.name
  address_prefixes     = ["10.0.0.0/23"]
}

# NSG
resource "azurerm_network_security_group" "nsg_tf" {
  name                = "nsg-tf"
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.poornesh_rg.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IP
resource "azurerm_public_ip" "poornesh_tfpip" {
  name                = "poornesh-tf"
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.poornesh_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# NIC
resource "azurerm_network_interface" "poornesh_nic_tf" {
  name                = "poornesh-nic-tf"
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.poornesh_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.poornesh_subnet_tf.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.poornesh_tfpip.id
  }
}

# NSG Association
resource "azurerm_network_interface_security_group_association" "nsg_nic_assoc" {
  network_interface_id      = azurerm_network_interface.poornesh_nic_tf.id
  network_security_group_id = azurerm_network_security_group.nsg_tf.id
}

# VM
resource "azurerm_linux_virtual_machine" "poornesh_vm_tf" {
  name                = "poornesh-vm-tf"
  resource_group_name = azurerm_resource_group.poornesh_rg.name
  location            = "australiaeast"
  size                = "Standard_D2ls_v5"
  admin_username      = "poornesh"
  admin_password      = "Poornesh@123"

  network_interface_ids = [
    azurerm_network_interface.poornesh_nic_tf.id
  ]

  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name = "poornesh-vm-tf"
}

# Output
output "public_ip_address" {
  value = azurerm_public_ip.poornesh_tfpip.ip_address
}
