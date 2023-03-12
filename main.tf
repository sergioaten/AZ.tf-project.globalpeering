terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "3.46.0"
        }
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

#EastUS -> Network -> Create Virtual network
resource "azurerm_virtual_network" "vnet-ue" {
    name                = "EastUS-VNet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
}

#WestEurope -> Network -> Create Virtual network
resource "azurerm_virtual_network" "vnet-euw" {
    name                = "WestEurope-VNet"
    address_space       = ["10.1.0.0/16"]
    location            = "westeurope"
    resource_group_name = azurerm_resource_group.rg.name
}

#EastUS -> Network -> Create Subnet
resource "azurerm_subnet" "subnet-ue" {
    name                 = "Subnet0"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet-ue.name
    address_prefixes     = ["10.0.0.0/24"]
}

#WestEurope -> Network -> Create Subnet
resource "azurerm_subnet" "subnet-euw" {
    name                 = "Subnet0"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet-euw.name
    address_prefixes     = ["10.1.0.0/24"]
}

#EastUS -> Virtual machine
resource "azurerm_linux_virtual_machine" "vm-ue" {
    name                    = "EastUS-VM"
    resource_group_name     = azurerm_resource_group.rg.name
    location                = "eastus"
    size                    = var.vmsize
    admin_username          = var.vmuser
    network_interface_ids   =   [ 
        azurerm_network_interface.nic-ue.id
    ]
    
    admin_ssh_key {
        username    = var.vmuser
        public_key  = var.public-sshkey
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

#WestEurope -> Virtual machine
resource "azurerm_linux_virtual_machine" "vm-euw" {
    name                    = "WestEurope-VM"
    resource_group_name     = azurerm_resource_group.rg.name
    location                = "westeurope"
    size                    = var.vmsize
    admin_username          = var.vmuser
    network_interface_ids   =   [ 
        azurerm_network_interface.nic-euw.id
    ]
    
    admin_ssh_key {
        username    = var.vmuser
        public_key  = var.public-sshkey
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

#EastUS -> Virtual Machine -> Create NIC
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

#WestEurope -> Virtual Machine -> Create NIC
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

#EastUS -> Network -> PublicIP
resource "azurerm_public_ip" "pip" {
    name                = "EastUS-PIP"
    resource_group_name = azurerm_resource_group.rg.name
    location            = "eastus"
    allocation_method   = "Static"
}

### PEERINGS ###

#Network -> Peering EastUS - WestEurope
resource "azurerm_virtual_network_peering" "peer-ue-euw" {
    name                            = "peer-EastUS-WestEurope"
    resource_group_name             = azurerm_resource_group.rg.name
    virtual_network_name            = azurerm_virtual_network.vnet-ue.name
    remote_virtual_network_id       = azurerm_virtual_network.vnet-euw.id
    allow_virtual_network_access    = true
    allow_forwarded_traffic         = true
    allow_gateway_transit           = false
}

#Network -> Peering WestEurope - EastUS
resource "azurerm_virtual_network_peering" "peer-euw-ue" {
    name                            = "peer-WestEurope-EastUS"
    resource_group_name             = azurerm_resource_group.rg.name
    virtual_network_name            = azurerm_virtual_network.vnet-euw.name
    remote_virtual_network_id       = azurerm_virtual_network.vnet-ue.id
    allow_virtual_network_access    = true
    allow_forwarded_traffic         = true
    allow_gateway_transit           = false
}

### NETWORK TEST ###

resource "null_resource" "shellscript" {
    connection {
        type        =   "ssh"
        user        =   var.vmuser
        host        =   azurerm_public_ip.pip.ip_address
        private_key =   file(var.path-private-sshkey)
    }

    provisioner "file" {
        source      = "script.sh"
        destination = "/tmp/script.sh"
    }

    provisioner "remote-exec" {
        inline     = [
            "chmod +x /tmp/script.sh",
            "sh /tmp/script.sh"
        ]
    }
    
    depends_on = [
        azurerm_linux_virtual_machine.vm-ue,
        azurerm_linux_virtual_machine.vm-euw
    ]
}