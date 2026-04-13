variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "frontend_subnet_name" {
  type = string
}

variable "frontend_subnet_prefixes" {
  type    = list(string)
  default = ["10.0.1.0/24"]
}

variable "backend_subnet_name" {
  type = string
}

variable "backend_subnet_prefixes" {
  type    = list(string)
  default = ["10.0.2.0/24"]
}

variable "frontend_vm_name" {
  type = string
}

variable "backend_vm_name" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "mysql_server_name" {
  type = string
}

variable "mysql_admin_username" {
  type = string
}

variable "mysql_admin_password" {
  type      = string
  sensitive = true
}

variable "mysql_database_name" {
  type    = string
  default = "bookstore"
}