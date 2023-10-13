# Set up grafana node
# Terraform code based on documentation https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html

# Create Public ip for grafana dashboard
resource "azurerm_public_ip" "grafana" {
  name                         = "elk-stack-grafana-pip"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method = "Static"
}

# Network security group for limiting access to grafana public dashboard
resource "azurerm_network_security_group" "grafana" {
  name                = "elk-grafana"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  security_rule {
    name                       = "allowGrafanaWebInterface"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "${var.nsgip}"
    destination_address_prefix = "*"
  }
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
}

# Create network interface, attach public ip that we have created
resource "azurerm_network_interface" "grafana" {
  name                = "weu-elk-grafana1"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "weu-elk-grafana1"
    subnet_id                     = "${azurerm_subnet.network.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.grafana.id

  }
}

# Connect the security group to the grafana network interface
resource "azurerm_network_interface_security_group_association" "grafana" {
  network_interface_id      = azurerm_network_interface.grafana.id
  network_security_group_id = azurerm_network_security_group.grafana.id
}

# Create VM
resource "azurerm_virtual_machine" "grafana" {
  name                  = "weu-elk-grafana1"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.grafana.id}"]
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "weu-elk-grafana1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

   os_profile {
     computer_name  = "weu-elk-grafana1"
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

# Install chef-solo, start chef bootstrap
resource "azurerm_virtual_machine_extension" "grafana" {
  name                 = "weu-elk-grafana1"
  virtual_machine_id   = azurerm_virtual_machine.grafana.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on           = [azurerm_virtual_machine.grafana]
}

  data "azurerm_public_ip" "grafana" {
  name                = "${azurerm_public_ip.grafana.name}"
  resource_group_name = "${azurerm_virtual_machine.grafana.resource_group_name}"
}

output "grafana_public_ip_address" {
  value = "${data.azurerm_public_ip.grafana.ip_address}"
}
