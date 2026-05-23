terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.74.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
features {
  
}
subscription_id = "1dc07c30-4f02-476a-98b4-89b0d8304e01"
}

resource "azurerm_resource_group" "rg" {

    name = "rg1-ntms-vaibhav"
    location = "east us"
      
}

resource "azurerm_virtual_network" "vnet" {

    name = "vnet-vaibhav"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    address_space = [ "10.1.0.0/16" ]
}

resource "azurerm_subnet" "snet" {

name = "vnet-vaibhav-snet"
resource_group_name = azurerm_resource_group.rg.name
virtual_network_name = azurerm_virtual_network.vnet.name
address_prefixes = [ "10.1.0.0/24" ]
}

resource "azurerm_network_security_group" "nsg" {
    name = "vnet-vaibhav-nsg"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    }

resource "azurerm_network_security_rule" "nsgrule" {
  name                        = "nsgrule1"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg-ass" {
    subnet_id = azurerm_subnet.snet.id
    network_security_group_id = azurerm_network_security_group.nsg.id
    depends_on = [ 
    azurerm_subnet.snet,
    azurerm_network_security_group.nsg
]
}

resource "azurerm_public_ip" "pip" {
  name = "vbpip"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_network_interface" "nic1" {
  name = "nic1"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

ip_configuration {
  name = "internal"
  subnet_id = azurerm_subnet.snet.id
  private_ip_address_allocation = "Dynamic"
  public_ip_address_id = azurerm_public_ip.pip.id
}
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "vaibhav-machine"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}