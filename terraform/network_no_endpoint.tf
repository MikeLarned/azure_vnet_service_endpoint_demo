# Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = "56f31ed7-84da-467b-80d2-71d3b7d2a7ce"
    client_id       = "c371f24b-9107-40f8-848f-5146f5c15d4b"
    client_secret   = "t-O7hX^d]{9NV7l?PYl$mp:g3ruvZI->QCBRT{c{*&o5oUz7}.pF%"
    tenant_id       = "911630eb-3460-44db-b2a7-433e8547de63" # DirectoryID
}

# Virtual Network Setup 
#   No Service Endpoints enabled on the vnet.  Traffic from our app to Azure services are
#   routed over the public internet

resource "azurerm_resource_group" "network" {
    name     = "rg-endpoints-demo-wu2"
    location = "westus2"
}

resource "azurerm_network_security_group" "network" {
  name                = "vnet-nsg-endpoints-demo-wu2"
  location            = "${azurerm_resource_group.network.location}"
  resource_group_name = "${azurerm_resource_group.network.name}"
}

resource "azurerm_virtual_network" "network" {
  name                = "vnet-endpoints-demo-wu2"
  resource_group_name = "${azurerm_resource_group.network.name}"
  location            = "${azurerm_resource_group.network.location}"
  address_space       = "10.200.0.0/16"
}

resource "azurerm_subnet" "front" {
  name                 = "front"
  resource_group_name  = "${azurerm_resource_group.network.name}"
  address_prefix       = "10.200.10.0/24"
  virtual_network_name = "${azurerm_virtual_network.network.name}"
}

resource "azurerm_subnet" "back" {
  name                 = "back"
  resource_group_name  = "${azurerm_resource_group.network.name}"
  address_prefix       = "10.200.10.0/24"
  virtual_network_name = "${azurerm_virtual_network.network.name}"
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = "${azurerm_resource_group.network.name}"
  address_prefix       = "10.201.0.0/24"
  virtual_network_name = "${azurerm_virtual_network.network.name}"
}

# PostGre Database
resource "azurerm_postgresql_server" "data" {
  name                = "postgre-endpoints-demo-wu2"
  location            = "${azurerm_resource_group.network.location}"
  resource_group_name = "${azurerm_virtual_network.network.name}"

  sku {
    name     = "GP_Gen5_2"
    capacity = 2
    tier     = "GeneralPurpose"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "admin"
  administrator_login_password = "admin"
  version                      = "9.6"
  ssl_enforcement              = "Enabled"
}

# App (Linux VM on the Front Subnet)
resource "azurerm_network_interface" "nic" {
    name                      = "app-nic-endpoints-demo-wu2"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.network.name}"
    network_security_group_id = "${azurerm_network_security_group.network.id}"

    ip_configuration {
        name                          = "app-nic-config-endpoints-demo-wu2"
        subnet_id                     = "${azurerm_subnet.front.id}"
        private_ip_address_allocation = "static"
        private_ip_address            = "10.200.10.1"
    }
}

resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "app-endpoints-demo-wu2"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.network.location}"
    network_interface_ids = ["${azurerm_network_interface.nic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "app-endpoints-vm"
        admin_username = "azureuser"
        admin_password = "password"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }
}


# Resource
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-create-complete-vm
# https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal