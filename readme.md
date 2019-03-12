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

Before setting up the environment through the ```network.tf``` script, set the locals variable for public_ip to your public IP.  This ensures you can access the storage account from your developer maching.

```
locals {
  public_ip = "XX.XXX.XXX.XXX"
}
```

To setup the environment:

1. **Update Terraform AzureRM Provider Settings**

    At the top of the network.tf script. You will need an App registration in Azure Active Directory with a client id and secret that has contributor access to the subscription.  See the [Service Principal Client Secret](https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_secret.html) documentation.

    ```
    provider "azurerm" {
        subscription_id = "SUBSCRIPTION_ID"
        client_id       = "CLIENT_ID"
        client_secret   = "CLIENT_SECRET"
        tenant_id       = "DIRECTORY_ID" # DirectoryID
    }
    ```
2.  **Plan and Apply the Terraform script**

    Sets up the network, storage account, subnets, virtual machine and additional infrastrucre to test the network.

    Plan

    ```
    terraform plan -out out.plan
    ```

    Apply
    ```
    terraform apply out.plan
    ```

3.  **SSH into the VM**  

    You first need to get the public ip of the virtual machine on the network.

    ```
    az network public-ip show -g rg-endpoints-demo-wu2 -n app-publicip-endpoints-demo-wu2 --query ipAddress
    ```

    Using the public ip, SSH into the virtual machine. The demo uses a username and password to SSH.  You wouldn't want to use this setup in a production environment.  The password setup in the network terraform script is ```T3x4stoast```.

    ```
    ssh azureuser@PUBLIC_IP_ADDRESS
    ssh azureuser@52.191.167.195 (ex)
    ```

    If you see an erro fro the az cli, you may need to login with az login first for your test account. 

    ```
    {
        "error":"invalid_grant",
        "error_description":"AADSTS40016:" ...
    }
    ```

4.  **Install the Azure CLI** 

    The ```build\azurecli.sh``` script installs Azure CLI into your virtual machine.  You can execute that script remotely from my repo.  See [executing remote scripts](https://stackoverflow.com/questions/5735666/execute-bash-script-from-url) on StackOverflow

    ```
    curl -s https://raw.githubusercontent.com/MikeLarned/azure_vnet_service_endpoint_demo/master/build/azurecli.sh | bash
    ```

5.  **Storage Account Key**  

    To write blobs to the storage, we need the storage account key.  You can access this key through the Azure CLI.  Key1 or Key2 should work.

    ```
    az storage account keys list -g rg-endpoints-demo-wu2 -n saendpointsdemowu2
    ```

6.  **Enable Request Logging in Azure Storage**  

    You want to enable minute request logging for ```saendpointsdemowu2``` storage account.  This writes logs to a folder called $logs.  These log files allow us to view inbound ips for storage account requests.  

    ```
    az storage logging update --log "rwd" --retention "7" --services "b" --account-key "KEY" --account-name "saendpointsdemowu2"
    az storage metrics update --log "rwd" --retention "7" --services "b" --api "true" --minute "true" --hour "true" --account-key "KEY" --account-name "saendpointsdemowu2"
    ```


## Write Blobs to Storage

From the VM you SSH'd into, execute the ```storage.sh``` script remotely.  This script generates a blob with a GUID name and writes it to the storage account.  You need to ensure the last parameter to the script is the key you received in Step 5 of the setup.

```
    curl -s https://raw.githubusercontent.com/MikeLarned/azure_vnet_service_endpoint_demo/master/build/storage.sh |  bash -s "saendpointsdemowu2" "KEY"
```

## Reviewing the Logs

Log files are located in the $logs folder inside of the storage container.  Open the folders until you get down to the days and hours logs.  For example, my log file was located in ```$logs\blob\2019\03\12\0200\000000.log```.  Open the log file and look for a row containing ```1.0;2019-03-12T02:58:14.2840912Z;PutBlob;Success;```.  If you split that row by the ```;``` delimiter, line 15 or 16 should contain the inbound IP of the request.

```
0
10.200.10.5:53262
2018-03-28
```

Here we can see ```10.200.10.5```, the private IP assigned by my virtual network back subnet.  
