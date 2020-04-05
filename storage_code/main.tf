
provider "azurerm" {}

resource "azurerm_resource_group" "storage" {
  name     = "storageresourcegroup"
  location = "UK SOUTH"
}

resource "azurerm_storage_account" "account" {
  name = "${azurerm_resource_group.storage.name}"
  location = "${azurerm_resource_group.storage.location}"
  account_tier = "Standard"
  resource_group_name = "${azurerm_resource_group.storage.name}"
  account_replication_type = "LRS"
}


resource "azurerm_storage_container" "container" {
    name = "udemytestcontainer"
    storage_account_name = "${azurerm_storage_account.account.name}"
    container_access_type = "private"
    resource_group_name = "${azurerm_resource_group.storage.name}"
}

resource "azurerm_storage_blob" "blob" {
    name = "udemytestblob"
    resource_group_name = "${azurerm_resource_group.storage.name}"
    storage_account_name = "${azurerm_storage_account.account.name}"
    storage_container_name = "${azurerm_storage_container.container.name}"
    type = "page"
    size = "5120"
}

resource "azurerm_storage_share" "share" {
    name = "udemytestshare"
    storage_account_name = "${azurerm_storage_account.account.name}"
    quota = 50 #size of share
    resource_group_name = "${azurerm_resource_group.storage.name}"
}