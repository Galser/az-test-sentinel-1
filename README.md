# az-test-sentinel-1

Simple test code for Azure to create several entities to test [Sentinel Foundation Policies Library] (https://github.com/hashicorp/terraform-foundational-policies-library) 



# Requiremetns

- To be executed in TFC/TFE
- You will need  to define 4 environmet variables with credentials : 
    - ARM_CLIENT_ID
    - ARM_CLIENT_SECRET
    - ARM_TENANT_ID
    - ARM_SUBSCRIPTION_ID

# Code

Let's define testing code in [main.tf](main.tf)

Something around lines : 

```Terraform
# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "agTFResourceGroup"
  location = var.location
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "agTFVnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "agTFSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "publicip" {
  name                = "agTFPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}


# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "agTFNSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

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

# Create network interface
resource "azurerm_network_interface" "nic" {
  name                      = "agNIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "agNICConfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "agTFVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "agOsDisk"
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
    computer_name  = "agTFVM"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

data "azurerm_public_ip" "ip" {
  name                = azurerm_public_ip.publicip.name
  resource_group_name = azurerm_virtual_machine.vm.resource_group_name
  depends_on          = [azurerm_virtual_machine.vm]
}
```
# Create and define authentication credentials. 

For creating Azure auth creds in this case we are going to use `az` CLI : 

1) Login to your account locally bye executing: `az login`
2) List your subscriptions: `az account list`

```JSON
[
  {
    "cloudName": "AzureCloud",
    "id": "0XXXXXX-XXXX-XXXX-bb9f-0a0243a9c9f2",
    "isDefault": true,
    "name": "Team XXXX",
    "state": "Enabled",
    "tenantId": "0eXXXXX-8XXX-4XXX-b4XX-e3b33b6c52ec",
    "user": {
      "name": "andrii@hashicorp.com",
      "type": "user"
    }
  }
]
```

3) Optional -  if you have several account you will need to select one : `az account set --subscription="<subscription_id>"`

4) We can now create the Service Principal which will have permissions to manage resources in the specified Subscription using the following command: 

```
$ az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/SUBSCRIPTION_ID"
```

This command will output 5 values:

```
{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "azure-cli-2017-06-05-10-41-15",
  "name": "http://azure-cli-2017-06-05-10-41-15",
  "password": "0000-0000-0000-0000-000000000000",
  "tenant": "00000000-0000-0000-0000-000000000000"
}
```

These values map to the Terraform variables like so:

    - ARM_CLIENT_ID
    - ARM_CLIENT_SECRET
    - ARM_TENANT_ID
    - ARM_SUBSCRIPTION_ID

|Return from AZ CLI| Env var|
|-|-|
|`appId`| should be defined in environement variable as `ARM_CLIENT_ID`; |
|`password`|  is the `ARM_CLIENT_SECRET`.|
|`tenant`|  is the `ARM_TENANT_ID` .|


# Running apply 

Example of log 

```
  
Terraform v0.14.0
Initializing plugins and modules...
azurerm_resource_group.rg: Creating...
azurerm_resource_group.rg: Creation complete after 2s [id=/subscriptions/0Xd01236b-9012-acca-bb9f-90213081230/resourceGroups/agTFResourceGroup]
azurerm_virtual_network.vnet: Creating...
azurerm_public_ip.publicip: Creating...
azurerm_network_security_group.nsg: Creating...
azurerm_public_ip.publicip: Creation complete after 9s [id=/subscriptions/0Xd01236b-9012-acca-bb9f-90213081230/resourceGroups/agTFResourceGroup/providers/Microsoft.Network/publicIPAddresses/agTFPublicIP]
azurerm_virtual_network.vnet: Still creating... [10s elapsed]
azurerm_network_security_group.nsg: Still creating... [10s elapsed]
azurerm_virtual_network.vnet: Creation complete after 11s [id=/subscriptions/0Xd01236b-9012-acca-bb9f-90213081230/resourceGroups/agTFResourceGroup/providers/Microsoft.Network/virtualNetworks/agTFVnet]
azurerm_subnet.subnet: Creating...
azurerm_network_security_group.nsg: Creation complete after 11s [id=/subscriptions/0Xd01236b-9012-acca-bb9f-90213081230/resourceGroups/agTFResourceGroup/providers/Microsoft.Network/networkSecurityGroups/agTFNSG]
azurerm_subnet.subnet: Creation complete after 5s [id=/subscriptions/0Xd01236b-9012-acca-bb9f-90213081230/resourceGroups/agTFResourceGroup/providers/Microsoft.Network/virtualNetworks/agTFVnet/subnets/agTFSubnet]
azurerm_network_interface.nic: Creating...
azurerm_network_interface.nic: Creation complete after 7s [id=/subscriptions/0Xd01236b-9012-acca-bb9f-90213081230/resourceGroups/agTFResourceGroup/providers/Microsoft.Network/networkInterfaces/agNIC]
azurerm_virtual_machine.vm: Creating...
azurerm_virtual_machine.vm: Still creating... [10s elapsed]
azurerm_virtual_machine.vm: Still creating... [20s elapsed]
azurerm_virtual_machine.vm: Creation complete after 27s [id=/subscriptions/0Xd01236b-9012-acca-bb9f-90213081230/resourceGroups/agTFResourceGroup/providers/Microsoft.Compute/virtualMachines/agTFVM]
data.azurerm_public_ip.ip: Reading...
data.azurerm_public_ip.ip: Read complete after 0s [id=/subscriptions/0Xd01236b-9012-acca-bb9f-90213081230/resourceGroups/agTFResourceGroup/providers/Microsoft.Network/publicIPAddresses/agTFPublicIP]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
```





# TODO

- [x] inital README
- [x] basic code
- [x] init env vars
    - [x] add that part to README
- [x] test code
- [ ] attach sentinel policy
- [ ] test code again
- [ ] update readme
