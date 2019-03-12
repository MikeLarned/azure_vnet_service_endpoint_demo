Configure the Microsoft Azure Provider
provider "azurerm" {
    subscription_id = ""
    client_id       = ""
    client_secret   = ""
    tenant_id       = "" # DirectoryID
}

locals {
  public_ip = "XX.XXX.XXX.XXX"
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

resource "azurerm_virtual_network" "network" {
  name                = "vnet-endpoints-demo-wu2"
  resource_group_name = "${azurerm_resource_group.network.name}"
  location            = "${azurerm_resource_group.network.location}"
  address_space       = ["10.200.0.0/16"]
}

resource "azurerm_subnet" "front" {
  name                 = "front"
  resource_group_name  = "${azurerm_resource_group.network.name}"
  address_prefix       = "10.200.10.0/24"
  virtual_network_name = "${azurerm_virtual_network.network.name}"
  service_endpoints = ["Microsoft.Storage"]
}

# Azure Storage Account
resource "azurerm_storage_account" "network" {
  name                     = "saendpointsdemowu2"
  resource_group_name      = "${azurerm_resource_group.network.name}"
  location                 = "${azurerm_resource_group.network.location}"
  account_tier             = "Standard"
  account_replication_type = "GRS"
  enable_https_traffic_only = true
  network_rules {
    virtual_network_subnet_ids = ["${azurerm_subnet.front.id}"]
    ip_rules                   = ["${local.public_ip}"]
  }
}

resource "azurerm_monitor_log_profile" "network" {
  name = "default"

  categories = [
    "Action",
    "Delete",
    "Write",
  ]

  locations = [
    "${azurerm_resource_group.network.location}"
  ]

  storage_account_id = "${azurerm_storage_account.network.id}"

  retention_policy {
    enabled = true
    days    = 7
  }
}

# App (Linux VM on the Front Subnet)

resource "azurerm_public_ip" "app" {
    name                         = "app-publicip-endpoints-demo-wu2"
    location                     = "${azurerm_resource_group.network.location}"
    resource_group_name          = "${azurerm_resource_group.network.name}"
    allocation_method            = "Static"
}

resource "azurerm_network_interface" "nic" {
    name                      = "app-nic-endpoints-demo-wu2"
    location                  = "${azurerm_resource_group.network.location}"
    resource_group_name       = "${azurerm_resource_group.network.name}"
    network_security_group_id = "${azurerm_network_security_group.network.id}"

    ip_configuration {
        name                          = "app-nic-config-endpoints-demo-wu2"
        subnet_id                     = "${azurerm_subnet.front.id}"
        private_ip_address_allocation = "static"
        private_ip_address            = "10.200.10.5"
        public_ip_address_id          = "${azurerm_public_ip.app.id}"
    }
}

resource "azurerm_virtual_machine" "app" {
    name                  = "app-endpoints-demo-wu2"
    location              = "${azurerm_resource_group.network.location}"
    resource_group_name   = "${azurerm_resource_group.network.name}"
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
        admin_password = "T3x4stoast"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }
}


# Resource
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/terraform-create-complete-vm
# https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal
# https://docs.microsoft.com/en-us/azure/azure-monitor/platform/diagnostic-logs-overview