provider "azurerm" {
  version         = "~> 1.44"
  alias           = "PFL"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

# RESOURCE GROUP 
resource "azurerm_resource_group" "scaleset" {
    name = "udemytestscaleset"
    location = "UK SOUTH"
}

# VNET
resource "azurerm_virtual_network" "scale_vnet" {
    name = "udemytestscalesetvnet"
    address_space = ["10.0.0.0/16"]
    resource_group_name = azurerm_resource_group.scaleset.name
    location = azurerm_resource_group.scaleset.location
}

#SUBNET 
resource "azurerm_subnet" "scale_subnet" {
    name = "udemytestscalesetsubet"  
    resource_group_name = azurerm_resource_group.scaleset.name
    virtual_network_name = azurerm_virtual_network.scale_vnet.name
    address_prefix = "10.0.2.0/24"
}

# SCALE SET 
resource "azurerm_virtual_machine_scale_set" "vmss" {
    name = "azureudemyscaleset"
    resource_group_name = azurerm_resource_group.scaleset.name
    location = azurerm_resource_group.scaleset.location
    zones = [1,2,3]
    upgrade_policy_mode = "Automatic"

    sku {
        name = "Standard_D1_v2"
        tier = "Standard"
        capacity = 1
    }    

    os_profile {
        computer_name_prefix = "udemy-scaleset"
        admin_username = "udemyadministrator"
        admin_password = "Password1234!"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    network_profile {
        name = "scaleprofile"
        primary = true

        ip_configuration {
            name = "vmss"
            subnet_id = azurerm_subnet.scale_subnet.id
            primary = true
        }
    }

    storage_profile_os_disk {
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_profile_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "18.04-LTS"
        version = "latest"
    }
}

# SCALE SET SETTINGS
resource "azurerm_monitor_autoscale_setting" "scale_setting" {
    name = "scalesettingudemy"
    resource_group_name = azurerm_resource_group.scaleset.name
    location = azurerm_resource_group.scaleset.location
    target_resource_id = azurerm_virtual_machine_scale_set.vmss.id

profile {
        name = "defaultProfile"

        capacity {
            default = 1
            minimum = 1
            maximum = 2 
        }
    
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 90
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 10
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

  }
}