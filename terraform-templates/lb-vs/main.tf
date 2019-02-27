# Login to Azure using 'az login' on your shell before running terraform commands. 
provider "azurerm" {
  version         = "1.22.0"
  subscription_id = "${var.AZ_SUBSCRIPTION_ID}"
  tenant_id       = "${var.AZ_TENANT_ID}"
}

resource "azurerm_resource_group" "rg" {
  location = "Australia East"
  name     = "${var.objectname_prefix}-rg-0"
}

# Vnet and subnet configuration <
resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.4.0.0/16"]
  location            = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-vnet-0"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_network_security_group" "nsg" {
  location            = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-nsg-0"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "allow_in_tcp443"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_in_tcp22"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet" "sn_mgmt" {
  address_prefix       = "10.4.0.0/24"
  name                 = "${var.objectname_prefix}-subnet-0"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
}

resource "azurerm_subnet" "sn_sync" {
  address_prefix       = "10.4.1.0/24"
  name                 = "${var.objectname_prefix}-subnet-1"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
}

resource "azurerm_subnet" "sn_ext" {
  address_prefix       = "10.4.2.0/24"
  name                 = "${var.objectname_prefix}-subnet-2"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
}
# Vnet and subnet configuration >

# NSG configuration <
resource "azurerm_subnet_network_security_group_association" "nsga-mgmt" {
  subnet_id                 = "${azurerm_subnet.sn_mgmt.id}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}

resource "azurerm_subnet_network_security_group_association" "nsga-ext" {
  subnet_id                 = "${azurerm_subnet.sn_ext.id}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}
# NSG configuration >

# Public IP configuration <
resource "azurerm_public_ip" "f5-0-mgmt-pip" {
  location            = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-pip-0"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "f5-1-mgmt-pip" {
  location            = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-pip-1"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "plb-pip" {
  location            = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-pip-2"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public IP configuration >

# Network interface configuration <
resource "azurerm_network_interface" "f5-0-mgmt" {
  name                = "${var.objectname_prefix}-ni-0"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "mgmt_ip"
    subnet_id                     = "${azurerm_subnet.sn_mgmt.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${cidrhost(azurerm_subnet.sn_mgmt.address_prefix, 10)}"
    public_ip_address_id          = "${azurerm_public_ip.f5-0-mgmt-pip.id}"
  }
}

resource "azurerm_network_interface" "f5-0-sync" {
  name                = "${var.objectname_prefix}-ni-1"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "self_ip"
    subnet_id                     = "${azurerm_subnet.sn_sync.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${cidrhost(azurerm_subnet.sn_sync.address_prefix, 10)}"
  }
}

resource "azurerm_network_interface" "f5-0-ext" {
  name                = "${var.objectname_prefix}-ni-2"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "self_ip"
    subnet_id                     = "${azurerm_subnet.sn_ext.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${cidrhost(azurerm_subnet.sn_ext.address_prefix, 10)}"
  }
}

resource "azurerm_network_interface" "f5-1-mgmt" {
  name                = "${var.objectname_prefix}-ni-3"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "mgmt_ip"
    subnet_id                     = "${azurerm_subnet.sn_mgmt.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${cidrhost(azurerm_subnet.sn_mgmt.address_prefix, 11)}"
    public_ip_address_id          = "${azurerm_public_ip.f5-1-mgmt-pip.id}"
  }
}

resource "azurerm_network_interface" "f5-1-sync" {
  name                = "${var.objectname_prefix}-ni-4"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "self_ip"
    subnet_id                     = "${azurerm_subnet.sn_sync.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${cidrhost(azurerm_subnet.sn_sync.address_prefix, 11)}"
  }
}

resource "azurerm_network_interface" "f5-1-ext" {
  name                = "${var.objectname_prefix}-ni-5"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "self_ip"
    subnet_id                     = "${azurerm_subnet.sn_ext.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${cidrhost(azurerm_subnet.sn_ext.address_prefix, 11)}"
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
    name                 = "public-vs-0"
    public_ip_address_id = "${azurerm_public_ip.plb-pip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "plb-bep" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.plb.id}"
  name                = "self_ips"
}

resource "azurerm_lb_probe" "plb-probe" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.plb.id}"
  name                = "tcp22"
  interval_in_seconds = 5
  port                = 22
}

resource "azurerm_network_interface_backend_address_pool_association" "plb-f5-0" {
  network_interface_id    = "${azurerm_network_interface.f5-0-ext.id}"
  ip_configuration_name   = "self_ip"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.plb-bep.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "plb-f5-1" {
  network_interface_id    = "${azurerm_network_interface.f5-1-ext.id}"
  ip_configuration_name   = "self_ip"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.plb-bep.id}"
}

resource "azurerm_lb_rule" "plb-rule" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.plb.id}"
  name                           = "lb-rule_selfips"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "public-vs-0"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.plb-bep.id}"
  probe_id = "${azurerm_lb_probe.plb-probe.id}"
  enable_floating_ip = true
}
# Public load balancer configuration >

# Internal load balancer configuration <
resource "azurerm_lb" "ilb" {
  location            = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-ilb-0"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "floating_selfip"
    subnet_id                     = "${azurerm_subnet.sn_ext.id}"
    private_ip_address            = "10.4.2.9"
    private_ip_address_allocation = "Static"
  }
}

resource "azurerm_lb_backend_address_pool" "ilb-bep" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.ilb.id}"
  name                = "self_ips"
}

resource "azurerm_lb_probe" "ilb-probe" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.ilb.id}"
  name                = "tcp22"
  interval_in_seconds = 5
  port                = 22
}

resource "azurerm_network_interface_backend_address_pool_association" "ilb-f5-0" {
  network_interface_id    = "${azurerm_network_interface.f5-0-ext.id}"
  ip_configuration_name   = "self_ip"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.ilb-bep.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "ilb-f5-1" {
  network_interface_id    = "${azurerm_network_interface.f5-1-ext.id}"
  ip_configuration_name   = "self_ip"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.ilb-bep.id}"
}

resource "azurerm_lb_rule" "ilb-rule" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id                = "${azurerm_lb.ilb.id}"
  name                           = "lb-rule_selfips"
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "floating_selfip"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.ilb-bep.id}"
  probe_id = "${azurerm_lb_probe.ilb-probe.id}"
  enable_floating_ip = true
}
# Internal load balancer configuration >

# Availability set and virtual machine configuration <
resource "azurerm_availability_set" "as" {
  name                        = "${var.objectname_prefix}-as-1"
  managed                     = true
  location                    = "${azurerm_resource_group.rg.location}"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  platform_fault_domain_count = 2
}
resource "azurerm_virtual_machine" "vm-f5-0" {
  availability_set_id = "${azurerm_availability_set.as.id}"
  location                     = "${azurerm_resource_group.rg.location}"
  name                         = "${var.objectname_prefix}-vm-0"
  network_interface_ids        = ["${azurerm_network_interface.f5-0-mgmt.id}", "${azurerm_network_interface.f5-0-sync.id}", "${azurerm_network_interface.f5-0-ext.id}"]
  primary_network_interface_id = "${azurerm_network_interface.f5-0-mgmt.id}"
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
    name              = "${var.objectname_prefix}-vm-0-disk-0"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "120"
  }

  os_profile {
    computer_name  = "${var.objectname_prefix}-f5-vm-0"
    admin_username = "${var.F5_USERNAME}"
    admin_password = "${var.F5_PASSWORD}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
# Availability set and virtual machine configuration >