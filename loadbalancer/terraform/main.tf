# PROVIDER 
provider "azurerm" {version = "= 1.31.0"}

# RESOURCE GROUP 
resource "azurerm_resource_group" "lbrg" {
    name = "lbtest"
    location = "UK SOUTH"
}

# STORAGE ACCOUNT
resource "azurerm_storage_account" "stor" {
    name = "lbstoragetest"
    location = "${azurerm_resource_group.lbrg.location}"
    resource_group_name = "${azurerm_resource_group.lbrg.name}"
    account_tier = "Standard"
    account_replication_type = "LRS"
}

# AVAILABILITY SET 
resource "azurerm_availability_set" "avset" {
    name = "lbavset"
    location = "${azurerm_resource_group.lbrg.location}"
    resource_group_name = "${azurerm_resource_group.lbrg.name}"
    platform_fault_domain_count = 2
    platform_update_domain_count = 2
    managed = true
}

# PUBLIC IP FOR THE LB
resource "azurerm_public_ip"  "pubip" {
    name = "pub-udemy-lb-test"
    location = "${azurerm_resource_group.lbrg.location}"
    resource_group_name = "${azurerm_resource_group.lbrg.name}"
    allocation_method = "Dynamic"
    domain_name_label = "lb-test-udemy-pub" # UNIQUE
}

# VNET 
resource "azurerm_virtual_network" "vnet" {
    name = "vnet"
    location = "${azurerm_resource_group.lbrg.location}"
    resource_group_name = "${azurerm_resource_group.lbrg.name}"
    address_space = ["10.0.0.0/16"]
}

# SUBNET 
resource "azurerm_subnet" "subnet" {
    name = "lbsubnet"
    virtual_network_name = "${azurerm_virtual_network.vnet.name}"
    address_prefix = "10.0.10.0/24"
    resource_group_name = "${azurerm_resource_group.lbrg.name}"
}

# LB 
resource "azurerm_lb" "lb" {
    name = "testlb"
    location = "${azurerm_resource_group.lbrg.location}"
    resource_group_name = "${azurerm_resource_group.lbrg.name}"

    frontend_ip_configuration {
        name = "lbfrontendip"
        public_ip_address_id = "${azurerm_public_ip.pubip.id}"
    }
}

# BACKEND ADDRESS POOL 
resource "azurerm_lb_backend_address_pool" "backend_pool" {
    resource_group_name = "${azurerm_resource_group.lbrg.name}"
    loadbalancer_id = "${azurerm_lb.lb.id}"
    name = "backendpool1"
}
# NAT RULE 
resource "azurerm_lb_nat_rule" "tcp" {
    resource_group_name = "${azurerm_resource_group.lbrg.name}"
    loadbalancer_id = "${azurerm_lb.lb.id}"
    name = "tcp-rule-${count.index+1}"
    protocol = "tcp"
    frontend_port = "5000${count.index+1}"
    backend_port  = "3389"
    frontend_ip_configuration_name = "lbfrontendip" 
    count = 2  
}

# LB RULE 
resource "azurerm_lb_rule" "lb_rule" {
    resource_group_name = "${azurerm_resource_group.lbrg.name}"
    loadbalancer_id = "${azurerm_lb.lb.id}"
    name = "LBRule"
    protocol = "tcp"
    frontend_port = "80"
    backend_port  = "80"
    frontend_ip_configuration_name = "lbfrontendip"  
    enable_floating_ip = false
    backend_address_pool_id = "${azurerm_lb_backend_address_pool.backend_pool.id}"  
    idle_timeout_in_minutes = 5 
    probe_id = "${azurerm_lb_probe.lb_probe.id}" # not created yet 
    depends_on = ["azurerm_lb_probe.lb_probe"]
}

# LB PROBE
resource "azurerm_lb_probe" "lb_probe" {
    resource_group_name = "${azurerm_resource_group.lbrg.name}"
    loadbalancer_id = "${azurerm_lb.lb.id}"
    name = "lbprobe"
    protocol = "tcp"
    port = 80
    interval_in_seconds = 5 
    number_of_probes = 2 
}

# NIC
resource "azurerm_network_interface" "nic" {
    name = "nic-${count.index+1}"
    location = "UK SOUTH"
    resource_group_name = "${azurerm_resource_group.lbrg.name}"   
    count = 2 

    ip_configuration {
        name = "ipconfig${count.index+1}"
        subnet_id = "${azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "Dynamic"
        load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.backend_pool.id}"]
        load_balancer_inbound_nat_rules_ids = ["${element(azurerm_lb_nat_rule.tcp.*.id,count.index)}"]
    }
}

# VIRTUAL MACHINES 
resource "azurerm_virtual_machine" "vm" {
  name                  = "vm${count.index}"
  location              = "UK SOUTH"
  resource_group_name = "${azurerm_resource_group.lbrg.name}" 
  availability_set_id   = "${azurerm_availability_set.avset.id}"
  vm_size               = "Standard_D1_v2"
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  count                 = 2

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name          = "osdisk${count.index}"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# provider "azurerm" {
#   version         = "~> 1.44"
#   alias           = "PFL"
#   subscription_id = var.subscription_id
#   client_id       = var.client_id
#   client_secret   = var.client_secret
# }

# # Resource Group
# resource "azurerm_resource_group" "lbrg" {
#   name     = "${var.prefix}-lb"
#   location = var.location
# }

# # Storage Account
# resource "azurerm_storage_account" "stor" {
#   name                     = "pfllbstorage"
#   location                 = azurerm_resource_group.lbrg.location
#   resource_group_name      = azurerm_resource_group.lbrg.name
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
# }

# # Availability Set
# resource "azurerm_availability_set" "avset" {
#   name                         = "lbavset"
#   location                     = azurerm_resource_group.lbrg.location
#   resource_group_name          = azurerm_resource_group.lbrg.name
#   platform_fault_domain_count  = 2
#   platform_update_domain_count = 2
#   managed                      = true
# }

# # Public IP for the LB
# resource "azurerm_public_ip" "lbpubip" {
#   name                = "${var.prefix}-lb-pub-ip"
#   location            = azurerm_resource_group.lbrg.location
#   resource_group_name = azurerm_resource_group.lbrg.name
#   allocation_method   = "Dynamic"
#   domain_name_label   = "${var.prefix}-lb-test-ip"
# }

# # VNET
# resource "azurerm_virtual_network" "vnet" {
#   name                = "${var.prefix}-vnet"
#   location            = azurerm_resource_group.lbrg.location
#   resource_group_name = azurerm_resource_group.lbrg.name
#   address_space       = ["10.0.0.0/16"]
# }

# # Subnet
# resource "azurerm_subnet" "subnet" {
#   name                 = "${var.prefix}-subnet"
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefix       = "10.0.10.0/24"
#   resource_group_name  = azurerm_resource_group.lbrg.name
# }

# # Load Balancer
# resource "azurerm_lb" "lb" {
#   name                = "${var.prefix}-lb"
#   location            = azurerm_resource_group.lbrg.location
#   resource_group_name = azurerm_resource_group.lbrg.name

#   frontend_ip_configuration {
#     name                 = "lbfrontendip"
#     public_ip_address_id = azurerm_public_ip.lbpubip.id
#   }
# }

# # Backend Address Pool
# resource "azurerm_lb_backend_address_pool" "backend_pool" {
#   resource_group_name = azurerm_resource_group.lbrg.name
#   loadbalancer_id     = azurerm_lb.lb.id
#   name                = "backendpool1"
# }

# # NAT Rule
# resource "azurerm_lb_nat_rule" "tcp" {
#   resource_group_name            = azurerm_resource_group.lbrg.name
#   loadbalancer_id                = azurerm_lb.lb.id
#   name                           = "tcp-rule-${count.index + 1}"
#   protocol                       = "tcp"
#   frontend_port                  = "5000${count.index + 1}"
#   backend_port                   = "3389"
#   frontend_ip_configuration_name = "lbfrontendip"
#   count                          = 2
# }

# # LB Rule
# resource "azurerm_lb_rule" "lb_rule" {
#   resource_group_name            = azurerm_resource_group.lbrg.name
#   loadbalancer_id                = azurerm_lb.lb.id
#   name                           = "LBRule"
#   protocol                       = "tcp"
#   frontend_port                  = "80"
#   backend_port                   = "80"
#   frontend_ip_configuration_name = "lbfrontendip"
#   enable_floating_ip             = false
#   backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
#   idle_timeout_in_minutes        = 5
#   probe_id                       = azurerm_lb_probe.lb_probe.id
#   depends_on                     = [azurerm_lb_probe.lb_probe]
# }

# # LB Probe
# resource "azurerm_lb_probe" "lb_probe" {
#   resource_group_name = azurerm_resource_group.lbrg.name
#   loadbalancer_id     = azurerm_lb.lb.id
#   name                = "lbprobe"
#   protocol            = "tcp"
#   port                = 80
#   interval_in_seconds = 5
#   number_of_probes    = 2
# }

# # NIC
# resource "azurerm_network_interface" "nic" {
#   name                = "nic-${count.index + 1}"
#   location            = azurerm_resource_group.lbrg.location
#   resource_group_name = azurerm_resource_group.lbrg.name
#   count               = 2

#   ip_configuration {
#     name                                    = "ipconfig${count.index + 1}"
#     subnet_id                               = azurerm_subnet.subnet.id
#     private_ip_address_allocation           = "Dynamic"
#     load_balancer_backend_address_pools_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
#     load_balancer_inbound_nat_rules_ids     = ["${element(azurerm_lb_nat_rule.tcp.*.id,count.index)}"]
#   }
# }

# # Virtual Machines
# resource "azurerm_virtual_machine" "main" {
#   count                 = 1
#   name                  = "${var.prefix}-${count.index + 1}"
#   location              = var.location
#   resource_group_name   = azurerm_resource_group.lbrg.name
#   network_interface_ids = [azurerm_network_interface.nic[0].id]
#   vm_size               = "Standard_DS1_v2"

#   # Uncomment this line to delete the OS disk automatically when deleting the VM
#   delete_os_disk_on_termination = true

#   # Uncomment this line to delete the data disks automatically when deleting the VM
#   delete_data_disks_on_termination = true

#   storage_image_reference {
#     publisher = "MicrosoftWindowsServer"
#     offer     = "WindowsServer"
#     sku       = "2019-Datacenter"
#     version   = "latest"
#   }

#   storage_os_disk {
#     name              = "${var.prefix}-os_disk"
#     caching           = "ReadWrite"
#     create_option     = "FromImage"
#     managed_disk_type = "Standard_LRS"
#   }

#   storage_data_disk {
#     name              = "${var.prefix}-data_disk"
#     lun               = 1
#     managed_disk_type = "Standard_LRS"
#     create_option     = "Empty"
#     disk_size_gb      = 10
#   }

#   os_profile {
#     computer_name  = "${var.prefix}-${count.index + 1}"
#     admin_username = "testadmin"
#     admin_password = "Password1234!"
#   }

#   os_profile_windows_config {

#   }

#   tags = {
#     environment = "dev"
#   }

# }
