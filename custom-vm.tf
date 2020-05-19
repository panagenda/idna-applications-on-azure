# creates virtual machine - static private ip
resource "azurerm_virtual_machine" "ifa" {
  name                  = "${var.prefix}-vm"
  count                 = var.subnet == "" ? 0 : 1
  location              = azurerm_resource_group.ifa.location
  resource_group_name   = azurerm_resource_group.ifa.name
  network_interface_ids = [azurerm_network_interface.ifa[0].id]
  vm_size               = var.vm_size
  # deletes disks on destroy
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = "${var.prefix}-osdisk"
    os_type           = "Linux"
    managed_disk_id   = azurerm_managed_disk.ifa.id
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "Attach"
  }

  lifecycle {
    # enable to prevent recreation
    prevent_destroy = "false"
  }

  depends_on = [azurerm_managed_disk.ifa]
}

# creates data disk - static private ip
resource "azurerm_managed_disk" "ifa-data" {
  name                 = "${var.prefix}-data"
  count                = var.subnet == "" ? 0 : 1
  location             = azurerm_resource_group.ifa.location
  resource_group_name  = azurerm_resource_group.ifa.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.data_disk
}
resource "azurerm_virtual_machine_data_disk_attachment" "ifa" {
  managed_disk_id    = azurerm_managed_disk.ifa-data[0].id
  count                 = var.subnet == "" ? 0 : 1
  virtual_machine_id = azurerm_virtual_machine.ifa[0].id
  lun                = "1"
  caching            = "ReadWrite"
}
