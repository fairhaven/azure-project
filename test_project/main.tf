terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
    /* random = {
      source  = "hashicorp/random"
      version = "=3.4.0"
    } */
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "test-rg" {
  name     = var.rsgname
  location = var.location

  tags = {
    environment = "dev"
  }
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "test-vn" {
  name                = "test-virtualNetwork"
  resource_group_name = var.rsgname
  location            = var.location
  address_space       = ["10.0.0.0/16"] #a list and accept multiple arguments

  tags = {
    environment = "dev"
  }
}

# Create a subnet within the resource group
resource "azurerm_subnet" "test-sub" {
  name                 = "test-subnet"
  resource_group_name  = var.rsgname
  virtual_network_name = azurerm_virtual_network.test-vn.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "test-pip" {
  name                = "myPublicIP"
  resource_group_name = var.rsgname
  location            = var.location
  allocation_method   = "Dynamic"
}

# Create a security group within the resource group
resource "azurerm_network_security_group" "test-sg" {
  name                = "test-securityGroup"
  resource_group_name = var.rsgname
  location            = var.location
  tags = {
    environment = "dev"
  }
}

#create a security group rule
resource "azurerm_network_security_rule" "test-sgr" {
  name                        = "test-securityGroup-rule"
  priority                    = 201
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "10.151.0.0/24"
  description                 = "rules-for-developers-and-admin"
  resource_group_name         = var.rsgname
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.test-sg.name
}

# Create network interface
resource "azurerm_network_interface" "test-nic" {
  name                = "myNIC"
  resource_group_name = var.rsgname
  location            = var.location

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.test-sub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.test-pip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "test-sgra" {
  network_interface_id      = azurerm_network_interface.test-nic.id
  network_security_group_id = azurerm_network_security_group.test-sg.id
}

# Generate random text for a unique storage account name
#resource "random_id" "random_id" {
#keepers = {
# Generate a new ID only when a new resource group is defined
# resource_group = var.rsgname
#}

# byte_length = 8
#}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "test-stgacct" {
  name                     = "mystorage3454act" #"diag${random_id.random_id.hex}"
  location                 = var.location
  resource_group_name      = var.rsgname
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "test-vm" {
  name                  = "myVM"
  location              = var.location
  resource_group_name   = var.rsgname
  admin_username        = "azureuser"
  admin_password        = "Logineer-123"
  network_interface_ids = [azurerm_network_interface.test-nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.test-stgacct.primary_blob_endpoint
  }
}

# Install IIS web server to the virtual machine
resource "azurerm_virtual_machine_extension" "web_server_install" {
  name                       = var.prefix
  virtual_machine_id         = azurerm_windows_virtual_machine.test-vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
    }
  SETTINGS
}


