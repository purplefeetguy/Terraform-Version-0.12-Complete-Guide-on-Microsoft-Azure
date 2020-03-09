provider "azurerm" {
  version         = "~> 1.44"
  alias           = "PFL"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

output "vnet_name" {
  value = "${azurerm_virtual_network.main.*.name}"
}

output "subnet_name" {
  value = "${azurerm_subnet.internal.*.name}"
}

output "virtual_machine_name" {
  value = "${azurerm_virtual_machine.main.*.name}"
}

output "virtual_machine_interface" {
  value = "${azurerm_network_interface.main.*.name}"
}

output "virtul_machine_location" {
  value = "${azurerm_virtual_machine.main.*.location}"
}
