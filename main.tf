terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "3.46.0"
        }
    }
    backend "azurerm" {
        resource_group_name     = "azure-devops"
        storage_account_name    = "azuredevopsmsm"
        container_name          = "terraform"
        key                     = "terraform.tfstate"
    }
}

provider "azurerm" {
    features{}
}

#Resource Group
resource "azurerm_resource_group" "rg" {
    name        = "RG-GlobalPeering"
    location    = "eastus"
}

### EAST US ###

#Network -> Create Virtual network
resource "azurerm_virtual_network" "vnet-ue" {
    name                = "EastUS-VNet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
}

#Network -> Create Subnet
resource "azurerm_subnet" "subnet-ue" {
    name                 = "Subnet0"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet-ue.name
    address_prefixes     = ["10.0.0.0/24"]
}

#Network -> PublicIP
resource "azurerm_public_ip" "pip" {
    name                = "EastUS-PIP"
    resource_group_name = azurerm_resource_group.rg.name
    location            = "eastus"
    allocation_method   = "Dynamic"
}

#Virtual machine
resource "azurerm_linux_virtual_machine" "vm-ue" {
    name                    = "EastUS-VM"
    resource_group_name     = azurerm_resource_group.rg.name
    location                = "eastus"
    size                    = "Standard_B1s"
    admin_username          = "azureuser"
    network_interface_ids   =   [ 
        azurerm_network_interface.nic-ue.id
        ]
    
    admin_ssh_key {
        username    = "azureuser"
        public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOKCnTES1YP+BCG/RzgEVuuozenQsa+IbXEATIb1ulLmcIZVDED09S22zOemGeeRmOmq1JmFYHZ3sNYl/sS7iTUn9RhYPTTq9LKgsFqkB7yNqJCG3SItjbUhQjXzO235Ql5OHqIxcwFoQ9qOGJ9EFZCKb6oziBqm1Khy9ttLpxd4aOFmaOVHBpNiy5APx3SyQOJe1v5b/OhMfBvHkWLpEN1ss7j4ilAH9eJCnFqWGsfxkQoL46jjIayWESTQ3l2xDINrPpmdoLuJqLxofsw5q1hD2FLgSnoBWtfdSqgEcaQwHan1Q1Qcyhcj7yQkx8iObl/fofqNcSOlzlR+RF2Rbm8DaFUMsj12/nIs3C2Y8O38k3fIGuoR1trvdqqK8ZUZCQtG5z+nOSUDDIAFegL0N0RaVj6ulVpHj6tdlkQSpHkOAEpdUaxsmHl/Xvob7e2m0sdZj8IznXM0a7XtYQlcOBuC+Oo3jLnEiZOtQcCTsxl9zi8tmr/u5Ok0GhwM0LBkE= generated-by-azure"
    }

    os_disk {
        caching                 = "ReadWrite"
        storage_account_type    = "Standard_LRS"
    }

    source_image_reference {
        publisher   = "Canonical"
        offer       = "0001-com-ubuntu-server-jammy"
        sku         = "22_04-lts-gen2"
        version     = "latest"
    }

    provisioner "file" {
        source      = "script.sh"
        destination = "/tmp/script.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /tmp/script.sh",
            "./script.sh"
        ]
    }
}

#Virtual Machine -> Create NIC
resource "azurerm_network_interface" "nic-ue" {
    name                = "EastUS-NIC"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
    ip_configuration {
        name                            = "internal"
        subnet_id                       = azurerm_subnet.subnet-ue.id
        private_ip_address_allocation   = "Dynamic"
        public_ip_address_id            = azurerm_public_ip.pip.id
    }
}

### EUROPE WEST ###

#Network -> Create Virtual network
resource "azurerm_virtual_network" "vnet-euw" {
    name                = "WestEurope-VNet"
    address_space       = ["10.1.0.0/16"]
    location            = "westeurope"
    resource_group_name = azurerm_resource_group.rg.name
}

#Network -> Create Subnet
resource "azurerm_subnet" "subnet-euw" {
    name                 = "Subnet0"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet-euw.name
    address_prefixes     = ["10.1.0.0/24"]
}

#Virtual machine
resource "azurerm_linux_virtual_machine" "vm-euw" {
    name                    = "WestEurope-VM"
    resource_group_name     = azurerm_resource_group.rg.name
    location                = "westeurope"
    size                    = "Standard_B1s"
    admin_username          = "azureuser"
    network_interface_ids   =   [ 
        azurerm_network_interface.nic-euw.id
        ]
    
    admin_ssh_key {
        username    = "azureuser"
        public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDOKCnTES1YP+BCG/RzgEVuuozenQsa+IbXEATIb1ulLmcIZVDED09S22zOemGeeRmOmq1JmFYHZ3sNYl/sS7iTUn9RhYPTTq9LKgsFqkB7yNqJCG3SItjbUhQjXzO235Ql5OHqIxcwFoQ9qOGJ9EFZCKb6oziBqm1Khy9ttLpxd4aOFmaOVHBpNiy5APx3SyQOJe1v5b/OhMfBvHkWLpEN1ss7j4ilAH9eJCnFqWGsfxkQoL46jjIayWESTQ3l2xDINrPpmdoLuJqLxofsw5q1hD2FLgSnoBWtfdSqgEcaQwHan1Q1Qcyhcj7yQkx8iObl/fofqNcSOlzlR+RF2Rbm8DaFUMsj12/nIs3C2Y8O38k3fIGuoR1trvdqqK8ZUZCQtG5z+nOSUDDIAFegL0N0RaVj6ulVpHj6tdlkQSpHkOAEpdUaxsmHl/Xvob7e2m0sdZj8IznXM0a7XtYQlcOBuC+Oo3jLnEiZOtQcCTsxl9zi8tmr/u5Ok0GhwM0LBkE= generated-by-azure"
    }

    os_disk {
        caching                 = "ReadWrite"
        storage_account_type    = "Standard_LRS"
    }

    source_image_reference {
        publisher   = "Canonical"
        offer       = "0001-com-ubuntu-server-jammy"
        sku         = "22_04-lts-gen2"
        version     = "latest"
    }
}

#Virtual Machine -> Create NIC
resource "azurerm_network_interface" "nic-euw" {
    name                = "WestEurope-NIC"
    location            = "westeurope"
    resource_group_name = azurerm_resource_group.rg.name
    ip_configuration {
        name                            = "internal"
        subnet_id                       = azurerm_subnet.subnet-euw.id
        private_ip_address_allocation   = "Dynamic"
    }
}

### PEERINGS ###

#Network -> Peering 1 to 2
resource "azurerm_virtual_network_peering" "peer-ue-euw" {
    name                            = "peer-EastUS-WestEurope"
    resource_group_name             = azurerm_resource_group.rg.name
    virtual_network_name            = azurerm_virtual_network.vnet-ue.name
    remote_virtual_network_id       = azurerm_virtual_network.vnet-euw.id
    allow_virtual_network_access    = true
    allow_forwarded_traffic         = true
    allow_gateway_transit           = false
}

#Network -> Peering 2 to 1
resource "azurerm_virtual_network_peering" "peer-euw-ue" {
    name                            = "peer-WestEurope-EastUS"
    resource_group_name             = azurerm_resource_group.rg.name
    virtual_network_name            = azurerm_virtual_network.vnet-euw.name
    remote_virtual_network_id       = azurerm_virtual_network.vnet-ue.id
    allow_virtual_network_access    = true
    allow_forwarded_traffic         = true
    allow_gateway_transit           = false
}