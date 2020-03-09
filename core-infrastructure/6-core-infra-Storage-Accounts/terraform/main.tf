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
  count                     = 1
  name                      = "${var.prefix}-nic-${count.index + 1}"
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name


  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_resource_group" "storage" {
  name     = "pfltfvmexstorage"
  location = var.location
}

resource "azurerm_storage_account" "account" {
  name = azurerm_resource_group.storage.name
  location = azurerm_resource_group.storage.location
  account_tier = "Standard"
  resource_group_name = azurerm_resource_group.storage.name
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
    name = "${azurerm_resource_group.storage.name}-container"
    storage_account_name = azurerm_storage_account.account.name
    container_access_type = "private"
    #resource_group_name = azurerm_resource_group.storage.name
}

resource "azurerm_storage_blob" "blob" {
    name = "${azurerm_resource_group.storage.name}-blob"
    #resource_group_name = azurerm_resource_group.storage.name
    storage_account_name = azurerm_storage_account.account.name
    storage_container_name = azurerm_storage_container.container.name
    type = "page"
    size = "5120"
}

resource "azurerm_storage_share" "share" {
    name = "${azurerm_resource_group.storage.name}-share"
    storage_account_name = azurerm_storage_account.account.name
    quota = 50 #size of share
    #resource_group_name = azurerm_resource_group.storage.name
}