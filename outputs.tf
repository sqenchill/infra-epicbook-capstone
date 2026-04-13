output "app_public_ip" {
  value = azurerm_public_ip.frontend_pip.ip_address
}

output "backend_private_ip" {
  value = azurerm_network_interface.backend_nic.private_ip_address
}

output "backend_public_ip" {
  value = azurerm_public_ip.backend_pip.ip_address
}

output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.mysql.fqdn
}

output "mysql_db_name" {
  value = azurerm_mysql_flexible_database.db.name
}

output "admin_username" {
  value = var.admin_username
}