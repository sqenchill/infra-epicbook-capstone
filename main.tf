resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "frontend" {
  name                 = var.frontend_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.frontend_subnet_prefixes
}

resource "azurerm_subnet" "backend" {
  name                 = var.backend_subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.backend_subnet_prefixes
}

resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "${var.frontend_vm_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "backend_nsg" {
  name                = "${var.backend_vm_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "frontend_ssh" {
  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.frontend_nsg.name
}

resource "azurerm_network_security_rule" "frontend_http" {
  name                        = "allow-http"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.frontend_nsg.name
}

resource "azurerm_network_security_rule" "backend_ssh" {
  name                        = "allow-ssh"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.backend_nsg.name
}

resource "azurerm_network_security_rule" "backend_app" {
  name                        = "allow-node-from-vnet"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.backend_nsg.name
}

resource "azurerm_public_ip" "frontend_pip" {
  name                = "${var.frontend_vm_name}-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "frontend_nic" {
  name                = "${var.frontend_vm_name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.frontend_pip.id
  }
}

resource "azurerm_network_interface" "backend_nic" {
  name                = "${var.backend_vm_name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "frontend_assoc" {
  network_interface_id      = azurerm_network_interface.frontend_nic.id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id
}

resource "azurerm_network_interface_security_group_association" "backend_assoc" {
  network_interface_id      = azurerm_network_interface.backend_nic.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}

resource "azurerm_linux_virtual_machine" "frontend_vm" {
  name                = var.frontend_vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1ms"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.frontend_nic.id
  ]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "backend_vm" {
  name                = var.backend_vm_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1ms"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.backend_nic.id
  ]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = var.mysql_server_name
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  zone                   = "1"
}

resource "azurerm_mysql_flexible_database" "db" {
  name                = var.mysql_database_name
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure" {
  name                = "allow-azure-services"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}