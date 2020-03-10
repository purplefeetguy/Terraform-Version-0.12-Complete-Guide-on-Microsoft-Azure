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

resource "azurerm_resource_group" "sql" {
  name     = "${var.prefix}-sqldb-rg"
  location = var.location
}

resource "azurerm_sql_server" "sql_server" {
  name = "${var.prefix}-sql-server"
  resource_group_name = azurerm_resource_group.sql.name
  location = azurerm_resource_group.sql.location
  version = "12.0"
  administrator_login = "Administrator"
  administrator_login_password = "Password123!"
}

resource "azurerm_sql_database" "sql_db" {
  name = "${var.prefix}-sqldb"
  resource_group_name = azurerm_resource_group.sql.name
  location = azurerm_resource_group.sql.location
  server_name = azurerm_sql_server.sql_server.name
  edition = "Basic"
  tags = {
      server_name = azurerm_sql_server.sql_server.name
  }
}

resource "azurerm_sql_firewall_rule" "firewall" {
    name = "${var.prefix}-sqldb-firewall"
    resource_group_name = azurerm_resource_group.sql.name
    server_name = azurerm_sql_server.sql_server.name
    start_ip_address = "0.0.0.0"
    end_ip_address = "0.0.0.0"
}