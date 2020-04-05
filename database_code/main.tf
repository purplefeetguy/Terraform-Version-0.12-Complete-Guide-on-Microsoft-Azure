#PROVIDER 
provider "azurerm" {}  

#RESOURCE GROUP 
resource "azurerm_resource_group" "sql" {
    name = "udemytestsqldb"
    location = "UK SOUTH"
}

#SERVER 
resource "azurerm_sql_server" "sql_server" {
    name = "azuresqlserverudemy"
    resource_group_name = "${azurerm_resource_group.sql.name}"
    location = "${azurerm_resource_group.sql.location}"
    version = "12.0" #SQL
    administrator_login = "AdministratorUdemy"
    administrator_login_password = "Password233!"
}

#DATABASE
resource "azurerm_sql_database" "sql_db" {
    name = "azuresqldbudemy"
    resource_group_name = "${azurerm_resource_group.sql.name}"
    location = "${azurerm_resource_group.sql.location}"  
    server_name = "${azurerm_sql_server.sql_server.name}"
    edition = "Basic"

    tags = {
        server_name = "${azurerm_sql_server.sql_server.name}"
    }
}

#FIREWALL
resource "azurerm_sql_firewall_rule" "firewall" {
    name = "azurefirewalludemy"
    resource_group_name = "${azurerm_resource_group.sql.name}"
    server_name = "${azurerm_sql_server.sql_server.name}"
    start_ip_address = "0.0.0.0"
    end_ip_address = "0.0.0.0"
}