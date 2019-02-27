# Azure Service Endpoint Demo

Azure Servie Endpoints allow you to extend the identity of your virtual network subnet
to certain Azure services such as SQL or Storage.  Extending identity of the network allows
the Azure service to only accept traffic from clients deployed within that subnet.  This allows the service to deny requests from other services and apps using the Azure backbone, reducing the surface
area for an attack.

This repository contains a terraform script to setup a virtual network, with an Ubuntu VM deployed to the 'front' subnet that writes blob to an Azure storage account.  The 'front' subnet has the Microsoft.Storage service endpoint enabled.  The storage account has a network rule applied to allow
requests originating from the front subnet to hit the storage endpoint.  

## Application

To simulate an real application living in our front subnet, an Ubuntu VM named ```app-endpoints-demo-wu2``` uses the Azure CLI to write blobs to our storage account.  This virutal machine is setup as part of the ```build\network.tf``` script.  A public ip is associated to the NIC to allow us to ssh into the machine with a username and password.

## Building the Network

To setup the environment:

1. Update the AzureRM provider settings at the top of the network.tf script. You will need an App registration in Azure Active Directory with a client id and secret that has contributor access to the subscription.  See the [Service Principal Client Secret](https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_secret.html) documentation.

```
provider "azurerm" {
    subscription_id = "SUBSCRIPTION_ID"
    client_id       = "CLIENT_ID"
    client_secret   = "CLIENT_SECRET"
    tenant_id       = "DIRECTORY_ID" # DirectoryID
}
```
2.  Plan and Apply the Terraform script.  This sets up the network, storage account, subnets, virtual machine and additional infrastrucre to test the network.

*Plan*

```
terraform plan -out out.plan
```

*Apply*
```
terraform apply out.plan
```

3.  SSH into the virtual machine.  You first need to get the public ip of the virtual machine
on the network.

```
az network public-ip show -g rg-endpoints-demo-wu2 -n app-publicip-endpoints-demo-wu2 --query ipAddress
```

Using the public ip, SSH into the virtual machine. The demo uses a username and password to SSH.  You wouldn't want to use this setup in a production environment.  The password setup in the network terraform script is ```T3x4stoast```.

```
ssh azureuser@PUBLIC_IP_ADDRESS
```

4.  Install the Azure CLI. The ```build\azurecli.sh``` script installs Azure CLI into your virtual machine.  You can execute that script remotely from my repo.

```
curl -s https://raw.githubusercontent.com/MikeLarned/azure_vnet_service_endpoint_demo/master/build/azurecli.sh | bash
```

5.  Storage Account Key.  To write blobs to the storage, we need the storage account key.  You can access this key through the Azure CLI.  Key1 or Key2 should work.

```
az storage account keys list -g rg-endpoints-demo-wu2 -n saendpointsdemowu2
```

6.  Enable Request Logging in Azure Storage.  You want to enable minute request logging for ```saendpointsdemowu2``` storage account.  This writes logs to a folder called $logs.  These log files allow us to view inbound ips for storage account requests.  


## Enables Request Logging for the Storage Account

## Write Blobs to Storage

## Reviewing the Logs