# creates virtual network
resource "azurerm_virtual_network" "ifa" {
  name                = "${var.prefix}-network"
  count               = var.subnet == "" ? 1 : 0
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.ifa.location
  resource_group_name = azurerm_resource_group.ifa.name
}

# creates internal subnet
resource "azurerm_subnet" "ifa" {
  name                 = "${var.prefix}-subnet"
  count                = var.subnet == "" ? 1 : 0
  resource_group_name  = azurerm_resource_group.ifa.name
  virtual_network_name = azurerm_virtual_network.ifa[0].name
  address_prefix       = "10.0.2.0/24"
}
# requests public ip
resource "azurerm_public_ip" "ifa" {
  name                    = "${var.prefix}-pip"
  count                   = var.subnet == "" ? 1 : 0
  location                = azurerm_resource_group.ifa.location
  resource_group_name     = azurerm_resource_group.ifa.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30

  tags = {
    environment = var.tags
  }
}

# creates network security group
resource "azurerm_network_security_group" "ifa" {
  name                        = "${var.prefix}-secgroup"
  count                       = var.subnet == "" ? 1 : 0
  location                    = azurerm_resource_group.ifa.location
  resource_group_name         = azurerm_resource_group.ifa.name
}

# creates network security group roles
resource "azurerm_network_security_rule" "ifa_ssh" {
  name                        = "${var.prefix}-sec-role-ssh"
  count                       = var.subnet == "" ? 1 : 0
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.source_address_prefixes
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = azurerm_resource_group.ifa.name
  network_security_group_name = azurerm_network_security_group.ifa[0].name
}

resource "azurerm_network_security_rule" "ifa_http" {
  name                        = "${var.prefix}-sec-role-http"
  count                       = var.subnet == "" ? 1 : 0
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefixes     = var.source_address_prefixes
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = azurerm_resource_group.ifa.name
  network_security_group_name = azurerm_network_security_group.ifa[0].name
}

resource "azurerm_network_security_rule" "ifa_https" {
  name                        = "${var.prefix}-sec-role-https"
  count                       = var.subnet == "" ? 1 : 0
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefixes     = var.source_address_prefixes
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = azurerm_resource_group.ifa.name
  network_security_group_name = azurerm_network_security_group.ifa[0].name
}

resource "azurerm_network_security_rule" "ifa_vnc" {
  name                        = "${var.prefix}-sec-role-vnc"
  count                       = var.subnet == "" ? 1 : 0
  priority                    = 104
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "5901"
  source_address_prefixes     = var.source_address_prefixes
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = azurerm_resource_group.ifa.name
  network_security_group_name = azurerm_network_security_group.ifa[0].name
}

resource "azurerm_network_security_rule" "ifa_incoming" {
  name                        = "${var.prefix}-sec-role-ifa-incoming"
  count                       = var.subnet == "" ? 1 : 0
  priority                    = 105
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = ["127.0.0.1", azurerm_public_ip.ifa[0].ip_address]
  destination_address_prefix  = "10.0.0.0/16"
  resource_group_name         = azurerm_resource_group.ifa.name
  network_security_group_name = azurerm_network_security_group.ifa[0].name

  depends_on = [azurerm_public_ip.ifa]
}

# creates nic
resource "azurerm_network_interface" "ifa-custom-public" {
  name                      = "${var.prefix}-nic"
  count                     = var.subnet == "" ? 1 : 0
  location                  = azurerm_resource_group.ifa.location
  resource_group_name       = azurerm_resource_group.ifa.name

  ip_configuration {
    name                          = "${var.prefix}-nic"
    subnet_id                     = azurerm_subnet.ifa[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ifa[0].id
  }
}

resource "azurerm_subnet_network_security_group_association" "ifa-custom-public-security-group" {
  network_security_group_id = azurerm_network_security_group.ifa[0].id
  subnet_id = azurerm_subnet.ifa[0].id
}
