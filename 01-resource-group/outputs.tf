output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "firewall_public_ip" {
  description = "Public IP address of Azure Firewall"
  value       = azurerm_public_ip.firewall_pip.ip_address
}

output "vm_private_ip" {
  description = "Private IP address of the NGINX VM"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}

output "bastion_public_ip" {
  description = "Public IP address of Azure Bastion"
  value       = azurerm_public_ip.bastion_pip.ip_address
}

output "nginx_access_url" {
  description = "URL to access NGINX through Azure Firewall"
  value       = "http://${azurerm_public_ip.firewall_pip.ip_address}:4000"
}