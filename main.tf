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

resource "azurerm_resource_group" "poornesh-rg" {
  name     = "poornesh-rg-us"
  location = "australiaeast"
  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_virtual_network" "poornesh-vnet-tf" {
  name                = "poornesh-vnet-tf"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.poornesh-rg.name
  location            = "australiaeast"
}

resource "azurerm_subnet" "poornesh-subnet-tf" {
  name                 = "poornesh-subnet-tf"
  resource_group_name  = azurerm_resource_group.poornesh-rg.name
  virtual_network_name = azurerm_virtual_network.poornesh-vnet-tf.name
  address_prefixes     = ["10.0.0.0/23"]
}

resource "azurerm_network_security_group" "nsg-tf" {
  name                = "nsg-tf"
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.poornesh-rg.name

  security_rule {
    name                       = "ssh"
    destination_port_range      = "22"
    access                     = "Allow"
    protocol                   = "Tcp"
    destination_address_prefix = "*"
    source_port_range          = "*"
    source_address_prefix      = "*"
    priority                   = 100
    direction                  = "Inbound"
  }
}

resource "azurerm_public_ip" "poornesh-tfpip" {
  name                = "poornesh-tf"
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.poornesh-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "poornesh-nic-tf" {
  name                = "poornesh-nic-tf"
  location            = "australiaeast"
  resource_group_name = azurerm_resource_group.poornesh-rg.name

  ip_configuration {
    name                          = "pip"
    subnet_id                     = azurerm_subnet.poornesh-subnet-tf.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.poornesh-tfpip.id
  }
  # lifecycle {
  #   ignore_changes = "true"
  # }
}

resource "azurerm_linux_virtual_machine" "poornesh-vm-tf" {
  name                   = "poornesh-vm-tf"
  resource_group_name    = azurerm_resource_group.poornesh-rg.name
  location               = "australiaeast"
  size                   = "Standard_D2ls_v5"
  admin_username         = "poornesh"
  network_interface_ids  = [azurerm_network_interface.poornesh-nic-tf.id]
  admin_password         = "Poornesh@123"
  # admin_ssh_key {
  #    username = "poornesh"
  #    public_key = file("/var/lib/jenkins/.ssh/id_rsa")
  # }
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

  computer_name                  = "poornesh-vm-tf"
  disable_password_authentication = false
}

output "public_ip_address" {
  value = azurerm_public_ip.poornesh-tfpip.ip_address
}

resource "azurerm_network_interface_security_group_association" "nsg_nic_assoc" {
  network_interface_id      = azurerm_network_interface.poornesh-nic-tf.id
  network_security_group_id = azurerm_network_security_group.nsg-tf.id
}

