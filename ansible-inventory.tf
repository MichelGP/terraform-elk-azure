### The Ansible inventory file
resource "local_file" "AnsibleInventory" {
 content = templatefile("${path.module}/templates/hosts.tpl",
   {
     elastic-ip                 = azurerm_public_ip.elastic.ip_address,
     kibana-ip                  = azurerm_public_ip.kibana.ip_address,
     grafana-ip                 = azurerm_public_ip.grafana.ip_address,
     logstash-ip                = azurerm_public_ip.logstash.ip_address,
     jumpbox-ip                 = azurerm_public_ip.jumpbox.ip_address,
   }
 )
 filename = "ansible/hosts"
}