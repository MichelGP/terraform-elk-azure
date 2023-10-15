# Set up elasticsearch node

# Create Public ip for elastic dashboard
resource "azurerm_public_ip" "elastic" {
  name                = "elk-stack-elastic-pip"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method   = "Static"
}

# Network security group for limiting access to elastic public dashboard
resource "azurerm_network_security_group" "elastic" {
  name                = "elk-elastic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  security_rule {
    name                       = "allowSsh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${var.nsgip}"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allowKibanaFrontend"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5601"
    source_address_prefix      = "${var.nsgip}"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allowFleet"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8220"
    source_address_prefix      = "${var.nsgip}"
    destination_address_prefix = "*"
  }
}

# Create network interface, attach public ip that we have created
resource "azurerm_network_interface" "elastic" {
  name                = "weu-elk-elastic1"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "weu-elk-elastic1"
    subnet_id                     = "${azurerm_subnet.network.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.elastic.id}"

  }
}

# Connect the security group to the grafana network interface
resource "azurerm_network_interface_security_group_association" "elastic" {
  network_interface_id      = azurerm_network_interface.elastic.id
  network_security_group_id = azurerm_network_security_group.elastic.id
}

# Create VM
resource "azurerm_virtual_machine" "elastic" {
  name                  = "weu-elk-elastic1"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.elastic.id}"]
  vm_size               = "Standard_DS2_v2"
  delete_os_disk_on_termination = true
  depends_on            = [azurerm_virtual_machine.elastic]
  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "weu-elk-elastic1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

   os_profile {
     computer_name  = "weu-elk-elastic1"
     admin_username = "${var.ssh_user}"
   }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.ssh_user}/.ssh/authorized_keys"
      key_data = tls_private_key.ssh-key.public_key_openssh
    }
  }

  tags = {
    environment = "development"
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "elastic" {
  virtual_machine_id = azurerm_virtual_machine.elastic.id
  location           = "${azurerm_resource_group.main.location}"
  enabled            = true

  daily_recurrence_time = "2200"
  timezone              = "W. Europe Standard Time"

  notification_settings {
    enabled         = false
    time_in_minutes = "60"
    webhook_url     = "https://sample-webhook-url.example.com"
  }
}