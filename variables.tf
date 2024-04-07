# Define variables
variable "location" {
  default = "eastus"
}

variable "admin_username" {
  default = "ecomadm"
}

variable "resource_group_name" {
  default = "rgConsul"
}

variable "vm_count" {
  default = 3
}

variable "vm_name_prefix" {
  default = "consul-server"
}

variable "vm_size" {
  default = "Standard_B2s"
}

variable "vnet_name_prefix" {
  default = "consul-vnet"
}

variable "vnet_cidr_block" {
  default = "10.0.0.0/16"
}

# Define list of security rule names and protocols
variable "security_rules" {
  type = list(object({
    name     = string
    protocol = string
  }))
  default = [
    { name = "AllowAllInboundTCP", protocol = "Tcp" },
    { name = "AllowAllInboundUDP", protocol = "Udp" },
  ]
}

variable "subnet_cidr_block" {
  default = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
}

variable "tags" {
  type = map(string)
  default = {
    "consul_datacenter" = "eastus"
    "applicationEnvironment" = "Dev"
    "applicationName"        = "Consul"
    "createdByUser"          = "mkoli"
  }
}

variable "cluster_size" {
  default = "3"
}

variable "consul_version" {
  default = "1.18.1"
}

variable "consul_datacenter" {
  default = "dc1"
}

variable "auto_join_subscription_id" {
  default = ""
}

variable "auto_join_tenant_id" {
  default = ""
}

variable "auto_join_client_id" {
  default = ""
}

variable "auto_join_secret_access_key" {
  default = ""
}
