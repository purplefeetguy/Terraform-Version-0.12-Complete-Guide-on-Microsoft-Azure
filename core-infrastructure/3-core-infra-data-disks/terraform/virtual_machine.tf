
resource "azurerm_managed_disk" "disk" {
  name                 = "${var.prefix}-managed_disk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  disk_size_gb         = 10
}

resource "azurerm_virtual_machine" "main" {
  count                 = 1
  name                  = "${var.prefix}-${count.index + 1}"
  location              = var.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-os_disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name              = "${var.prefix}-data_disk-01"
    lun               = 1
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    disk_size_gb      = 10
  }

  storage_data_disk {
    name              = "${var.prefix}-data_disk-02"
    lun               = 2
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    disk_size_gb      = 10
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.disk.name}"
    lun             = 3
    managed_disk_id = azurerm_resource_group.main.id
    create_option   = "Attach"
    disk_size_gb    = azurerm_managed_disk.disk.disk_size_gb
  }

  os_profile {
    computer_name  = "${var.prefix}-${count.index + 1}"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_windows_config {

  }

  tags = {
    environment = "dev"
  }

}
