resource "azurerm_resource_group" "rg" {
  location = "Australia East"
  name     = "${var.objectname_prefix}-rg-0"
}

# Vnet and subnet configuration >
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
  address_prefix            = "10.4.0.0/24"
  name                      = "${var.objectname_prefix}-subnet-0"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet.name}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}

resource "azurerm_subnet" "sn_sync" {
  address_prefix       = "10.4.1.0/24"
  name                 = "${var.objectname_prefix}-subnet-1"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
}

resource "azurerm_subnet" "sn_ext" {
  address_prefix            = "10.4.2.0/24"
  name                      = "${var.objectname_prefix}-subnet-2"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet.name}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}

# Vnet and subnet configuration <

# Public IP configuration >
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

resource "azurerm_public_ip" "elb-pip" {
  location            = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-pip-2"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Public IP configuration <

# Network interface configuration >
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
  name                = "${var.objectname_prefix}-ni-2"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "self_ip"
    subnet_id                     = "${azurerm_subnet.sn_ext.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "${cidrhost(azurerm_subnet.sn_ext.address_prefix, 11)}"
  }
}

# Network interface configuraton <

# Public load balancer configuration >
resource "azurerm_lb" "elb" {
  location = "${azurerm_resource_group.rg.location}"
  name                = "${var.objectname_prefix}-elb-0"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "vs-0"
    public_ip_address_id = "${azurerm_public_ip.elb-pip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "elb-bep" {
  resource_group_name = "${azurerm_resource_group.rg.name}"
  loadbalancer_id     = "${azurerm_lb.elb.id}"
  name                = "selfips"
}

resource "azurerm_network_interface_backend_address_pool_association" "elb-f5-0" {
  network_interface_id    = "${azurerm_network_interface.f5-0-ext.id}"
  ip_configuration_name   = "${azurerm_lb.elb.name}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.elb-bep.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "elb-f5-1" {
  network_interface_id    = "${azurerm_network_interface.f5-1-ext.id}"
  ip_configuration_name   = "${azurerm_lb.elb.name}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.elb-bep.id}"
}

# Public load balancer configuration <

resource "azurerm_availability_set" "as" {
  name                        = "${var.objectname_prefix}-as-1"
  managed                     = true
  location                    = "${azurerm_resource_group.rg.location}"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  platform_fault_domain_count = 2
}

