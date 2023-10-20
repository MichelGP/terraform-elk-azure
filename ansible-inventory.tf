### The Ansible inventory file
resource "local_file" "AnsibleInventory" {
 content = templatefile("${path.module}/templates/hosts.tpl",
   {
     elastic-ip                 = azurerm_public_ip.elastic.ip_address,
     grafana-ip                 = azurerm_public_ip.grafana.ip_address,
     kafka-ip                   = azurerm_public_ip.kafka.ip_address,
   }
 )
 filename = "ansible/lab"
}