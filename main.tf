
locals {
  consul_default_config = <<-EOF
  {
    "advertise_addr": "PRIVATEADDR",
    "data_dir": "/opt/consul/data",
    "client_addr": "0.0.0.0",
    "log_level": "INFO",
    "datacenter": "eastus",
    "ui": true,
    "retry_join": ["provider=azure tag_name=consul_datacenter tag_value=eastus subscription_id=${var.auto_join_subscription_id} tenant_id=${var.auto_join_tenant_id} client_id=${var.auto_join_client_id} secret_access_key=${var.auto_join_secret_access_key}"]
  }
  EOF
  consul_server_config  = <<-EOF
  {
    "server": true,
    "bootstrap_expect": ${var.cluster_size}
  }
  EOF
  consul_server_service = <<-EOF
  [Unit]
  Description=Consul Service Discovery Agent
  Documentation=https://www.consul.io/
  Requires=network-online.target
  After=network-online.target

  [Service]
  User=ecomadm
  Group=ecomadm
  ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
  ExecReload=/bin/kill -HUP $MAINPID
  KillSignal=SIGINT
  Restart=on-failure
  LimitNOFILE=65536

  [Install]
  WantedBy=multi-user.target
  EOF
  consul_agent_service  = <<-EOF
  [Unit]
  Description=Consul Service Discovery Agent
  Documentation=https://www.consul.io/
  Requires=network-online.target
  After=network-online.target

  [Service]
  User=ecomadm
  Group=ecomadm
  ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d/
  ExecReload=/bin/kill -HUP $MAINPID
  KillSignal=SIGINT
  Restart=on-failure
  LimitNOFILE=65536

  [Install]
  WantedBy=multi-user.target
  EOF
}


# Create virtual machine
resource "azurerm_linux_virtual_machine" "server" {
  count               = var.vm_count
  name                = "${var.vm_name_prefix}-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_ssh_key {
    username   = var.admin_username

  }
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  os_disk {
    name                 = "${var.vm_name_prefix}-${count.index}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  custom_data = base64encode(<<-SCRIPT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y curl unzip wget dnsmasq dnsutils ldnsutils -y
    sudo curl -LO https://releases.hashicorp.com/consul/${var.consul_version}/consul_${var.consul_version}_linux_amd64.zip
    sudo unzip consul_1.10.2_linux_amd64.zip
    sudo mv consul /usr/local/bin/
    sleep 5
    sudo sh -c 'echo "server=/consul/127.0.0.1#8600" >> /etc/dnsmasq.d/consul'
    sudo systemctl enable dnsmasq
    sudo systemctl restart dnsmasq
  SCRIPT
  )

  tags = var.tags
}

# To start consul server 
resource "null_resource" "consul-server" {
  count      = var.vm_count
  depends_on = [azurerm_linux_virtual_machine.server]
  connection {
    type        = "ssh"
    user        = "ecomadm"
    private_key = file("~/.ssh/id_rsa")
    host        = azurerm_linux_virtual_machine.server[count.index].public_ip_address
    timeout     = "10m"
  }
  provisioner "file" {
    source      = "install-consul"
    destination = "/tmp/"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/consul.d /opt/consul/data && sudo chmod -R 777 /opt/consul/",
      "sudo cp /tmp/install-consul/consul-config.hcl /etc/consul.d/consul-config.hcl",
      "echo '${local.consul_default_config}' | sudo tee /etc/consul.d/consul-default.json",
      "sudo sed -i 's/PRIVATEADDR/${azurerm_linux_virtual_machine.server[count.index].private_ip_address}/g' /etc/consul.d/consul-default.json",
      "echo '${local.consul_server_config}' | sudo tee /etc/consul.d/consul-server.json",
      "echo '${local.consul_server_service}' | sudo tee /etc/systemd/system/consul.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl restart consul",
      "sudo systemctl enable consul"
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo systemctl restart consul",
      "sudo systemctl enable consul" 
    ]
  }
}
# # # To start consul server 
# resource "null_resource" "consul-agent" {
#   #count      = var.vm_count
#   depends_on = [azurerm_linux_virtual_machine.server[1]]
#   connection {
#     type        = "ssh"
#     user        = "ecomadm"
#     private_key = file("~/.ssh/id_rsa")
#     host        = azurerm_linux_virtual_machine.server[1].public_ip_address
#     timeout     = "10m"
#   }
#   provisioner "file" {
#     source      = "install-consul"
#     destination = "/tmp/"
#   }
#   provisioner "remote-exec" {
#     inline = [
#       "sudo apt-get install consul -y",
#       "sudo mkdir -p /etc/consul.d /opt/consul/data",
#       "sudo cp /tmp/install-consul/consul-config.hcl /etc/consul.d/consul-config.hcl",
#       "echo '${local.consul_default_config}' | sudo tee /etc/consul.d/consul-default.json",
#       "sudo sed -i 's/PRIVATEADDR/${azurerm_linux_virtual_machine.server[1].private_ip_address}/g' /etc/consul.d/consul-default.json",
#       "echo '${local.consul_agent_service}' | sudo tee /etc/systemd/system/consul-agent.service",
#       "sudo systemctl daemon-reload",
#       "sudo systemctl restart consul-agent",
#       "sudo systemctl enable consul-agent"
#     ]
#   }
# }
