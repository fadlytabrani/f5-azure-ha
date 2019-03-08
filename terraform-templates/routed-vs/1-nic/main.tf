# Login to Azure using 'az login' on your shell before running terraform commands. 
provider "azurerm" {
  version         = "1.22.0"
  subscription_id = "${var.AZ_SUBSCRIPTION_ID}"
  tenant_id       = "${var.AZ_TENANT_ID}"
}
resource "azurerm_resource_group" "rg" {
  location = "${var.AZ_REGION}"
  name     = "${var.objectname_prefix}-rg-0"
}

# Vnet and subnet configuration <
resource "azurerm_virtual_network" "vnet" {
  address_space       = "${var.vnet_address_space}"
  location            = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-vnet-0"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "subnets" {

  # We'll have a subnet per interface.
  count                = "${length(var.interfaces)}"
  address_prefix       = "${element(var.interface_subnets, count.index)}"
  name                 = "${element(var.interfaces, count.index)}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
}
# Vnet and subnet configuration >

# UDR configuration >

# Create the route table and route objects ready for application on subnets if needed.
resource "azurerm_route_table" "route_tables" {
  name                = "${var.objectname_prefix}-rt-0"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  disable_bgp_route_propagation = true
}

resource "azurerm_route" "routes" {
  count = "${length(var.routed_subnets)}"
  name                = "route-${count.index}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  route_table_name    = "${azurerm_route_table.route_tables.0.name}"
  address_prefix      = "${element(var.routed_subnets, count.index)}"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address  = "${cidrhost(azurerm_subnet.subnets.0.address_prefix, 9)}"
  depends_on = ["azurerm_lb.ilb"]
} 
# UDR configuration <

# NSG configuration <
# Create "general" nsg a minimal ruleset for the solution.
resource "azurerm_network_security_group" "nsg" {
  location            = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-nsg-0"
  resource_group_name = "${azurerm_resource_group.rg.name}"

# TCP Rules <
  security_rule {
    name                       = "ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # F5 BIG-IP mirroring - https://support.f5.com/csp/article/K17333
  security_rule {
    name                       = "tcp1029"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1029"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # F5 BIG-IP iQuery, CMI - https://support.f5.com/csp/article/K17333
  security_rule {
    name                       = "tcp4353"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4353"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # F5 configuration utility when in 1-nic configuration. - https://support.f5.com/csp/article/K31003634
  security_rule {
    name                       = "tcp8443"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
# TCP Rules >

# UDP Rules <
  # F5 BIG-IP network failover - https://support.f5.com/csp/article/K9057
  security_rule {
    name                       = "udp1026"
    priority                   = 2001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "1026"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # F5 BIG-IP iQuery - https://support.f5.com/csp/article/K17333
  security_rule {
    name                       = "udp4353"
    priority                   = 2002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "4353"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
# UDP Rules >
}
resource "azurerm_subnet_network_security_group_association" "nsg_associations" {
  count                     = "${length(var.interfaces)}"
  subnet_id                 = "${element(azurerm_subnet.subnets.*.id, count.index)}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}
# NSG configuration >

# Public IP configuration <
resource "azurerm_public_ip" "public_ips" {

  # Create a public IP for each device for direct management and an additional one for the public load balancer frontend.
  count               =  3
  allocation_method   = "Static"
  location            = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-pip-${count.index}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku                 = "Standard"
}
# Public IP configuration >

# Network interface configuration <
resource "azurerm_network_interface" "network_interfaces" {
  count               = "${length(var.interfaces) * 2}"
  location            = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-ni-${count.index}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "${element(azurerm_subnet.subnets.*.name, count.index)}"


    private_ip_address            = "${cidrhost(element(azurerm_subnet.subnets.*.address_prefix, count.index), element(list("10", "11"), count.index))}"
    private_ip_address_allocation = "Static"
    subnet_id                     = "${element(azurerm_subnet.subnets.*.id, count.index)}"
    public_ip_address_id          = "${element(slice(azurerm_public_ip.public_ips.*.id, 0, 2), count.index)}"
  }
}
# Network interface configuraton >

# Public load balancer configuration <
resource "azurerm_lb" "plb" {
  location            = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-plb-0"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "feic-0"
    public_ip_address_id = "${azurerm_public_ip.public_ips.*.id[2]}"
  }
}

resource "azurerm_lb_backend_address_pool" "plb-bep" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.plb.id}"
  name                = "bep-0"
}

resource "azurerm_lb_probe" "plb-probe" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.plb.id}"
  name                = "tcp694"
  interval_in_seconds = 5
  port                = 694
}

resource "azurerm_network_interface_backend_address_pool_association" "plb-beps" {
  count                   = 2
  network_interface_id    = "${element(azurerm_network_interface.network_interfaces.*.id, count.index)}"
  ip_configuration_name   = "external"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.plb-bep.id}"
}

resource "azurerm_lb_rule" "plb-rule" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.plb.id}"
  name                           = "lbr-0"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${azurerm_lb.plb.frontend_ip_configuration.0.name}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.plb-bep.id}"
  probe_id                       = "${azurerm_lb_probe.plb-probe.id}"
  enable_floating_ip             = true
}
# Public load balancer configuration >

# Internal load balancer configuration <
resource "azurerm_lb" "ilb" {
  location            = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-ilb-0"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "feic-0"
    subnet_id                     = "${azurerm_subnet.subnets.0.id}"
    private_ip_address            = "${cidrhost(azurerm_subnet.subnets.0.address_prefix, 9)}"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "ilb-bep" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.ilb.id}"
  name                = "bep-0"
}

resource "azurerm_lb_probe" "ilb-probe" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.ilb.id}"
  name                = "tcp964"
  interval_in_seconds = 5
  port                = 964
}
resource "azurerm_network_interface_backend_address_pool_association" "ilb-beps" {
  count                   = 2
  network_interface_id    = "${element(azurerm_network_interface.network_interfaces.*.id, count.index)}"
  ip_configuration_name   = "external"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.ilb-bep.id}"
}
resource "azurerm_lb_rule" "ilb-rule" {
  resource_group_name            = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.ilb.id}"
  name                           = "lbr-0"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "${azurerm_lb.ilb.frontend_ip_configuration.0.name}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.ilb-bep.id}"
  probe_id                       = "${azurerm_lb_probe.ilb-probe.id}"
  enable_floating_ip             = true
}
# Internal load balancer configuration >

# Availability set and virtual machine configuration <
resource "azurerm_availability_set" "as" {
  name                        = "${var.objectname_prefix}-as-0"
  managed                     = true
  location                    = "${azurerm_resource_group.rg.location}"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  platform_fault_domain_count = 2
}

resource "azurerm_virtual_machine" "vms" {
  count                        = 2
  availability_set_id          = "${azurerm_availability_set.as.id}"
  location                     = "${azurerm_resource_group.rg.location}"
  name                         = "${var.objectname_prefix}-vm-${count.index}"
  network_interface_ids        = ["${element(azurerm_network_interface.network_interfaces.*.id, count.index)}"]
  primary_network_interface_id = "${element(azurerm_network_interface.network_interfaces.*.id, count.index)}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  vm_size                      = "${var.vm_size}"

  plan {
    name      = "f5-big-all-2slot-byol"
    publisher = "f5-networks"
    product   = "f5-big-ip-byol"
  }

  storage_image_reference {
    offer     = "f5-big-ip-byol"
    publisher = "f5-networks"
    sku       = "f5-big-all-2slot-byol"
    version   = "${var.f5_version}"
  }

  storage_os_disk {
    name              = "${var.objectname_prefix}-vm-${count.index}-disk-0"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "120"
  }

  os_profile {
    computer_name  = "${var.objectname_prefix}-vm-${count.index}"
    admin_username = "${var.F5_USERNAME}"
    admin_password = "${var.F5_PASSWORD}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_virtual_machine_extension" "vm_exts_bootstrap" {
  count = 2
  name                 = "f5bigip_1nic_ha_fo_bootstrap"
  location             = "${azurerm_resource_group.rg.location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.vms.*.name, count.index)}"
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "tmsh modify sys db provision.1nic value forced_enable;tmsh modify sys db provision.1nicautoconfig value disable;tmsh create ltm virtual _cloud_lb_probe_listener_ destination ${element(azurerm_network_interface.network_interfaces.*.ip_configuration.0.private_ip_address, count.index)}:694 source 168.63.129.16/32 ip-protocol tcp;echo tmsh modify ltm virtual _cloud_lb_probe_listener_ enabled>>/config/failover/active;echo tmsh modify ltm virtual _cloud_lb_probe_listener_ disabled>>/config/failover/standby;bigstart restart"
    }
  SETTINGS
}
# Availability set and virtual machine configuration >