# Set up Logstash node
# Terraform code based on documentation https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html

# Create Public ip for Logstash dashboard
resource "azurerm_public_ip" "logstash" {
  name                         = "elk-stack-logstash-pip"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method = "Static"
}

# Network security group for limiting access to logstash
resource "azurerm_network_security_group" "logstash" {
  name                = "elk-logstash"
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
}

resource "azurerm_network_interface" "logstash" {
  name                = "weu-elk-logstash1"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "weu-elk-logstash1"
    subnet_id                     = "${azurerm_subnet.network.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.logstash.id}"
  }
}

# Connect the security group to the logstash network interface
resource "azurerm_network_interface_security_group_association" "logstash" {
  network_interface_id      = azurerm_network_interface.logstash.id
  network_security_group_id = azurerm_network_security_group.logstash.id
}

resource "azurerm_virtual_machine" "logstash" {
  name                  = "weu-elk-logstash1"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.logstash.id}"]
  vm_size               = "Standard_B2s"
  delete_os_disk_on_termination = true
  depends_on            = [azurerm_virtual_machine.jumpbox,azurerm_virtual_machine.elastic]

    provisioner "file" {
      source      = "chef"
      destination = "/tmp/"

      connection {
        type     = "ssh"
        user     = "${var.ssh_user}"
        host = "weu-elk-logstash1"
        private_key = tls_private_key.ssh-key.private_key_openssh
        agent    = false
      #  key_file = "${file("~/.ssh/id_rsa")}"
        bastion_user     = "${var.ssh_user}"
        bastion_host     = "${data.azurerm_public_ip.jumpbox.ip_address}"
        bastion_private_key = tls_private_key.ssh-key.private_key_openssh
        timeout = "6m"
      }
    }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  storage_os_disk {
    name              = "weu-elk-logstash1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

   os_profile {
     computer_name  = "weu-elk-logstash1"
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

resource "azurerm_virtual_machine_extension" "logstash" {
  name                 = "weu-elk-logstash1"
  virtual_machine_id   = azurerm_virtual_machine.logstash.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  depends_on           = [azurerm_virtual_machine.logstash]

  settings = <<SETTINGS
    {
        "commandToExecute": "curl -L https://omnitruck.chef.io/install.sh | sudo bash; chef-solo --chef-license accept-silent -c /tmp/chef/solo.rb -o elk-stack::repo-setup,elk-stack::logstash,elk-stack::monitoring"
    }
SETTINGS
}
