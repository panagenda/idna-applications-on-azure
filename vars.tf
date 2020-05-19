# Resource Group
variable resource_group_name {
    default = "pana-ifa-rg"
}

# virutal machine size
variable vm_size {
    default = "Standard_B2ms"
}

# data disk size
variable data_disk {
    default = "100"
}

# prefix
variable prefix {
    default = "panaifa"
}

# location
variable location {
    default = "westeurope"
}

# tags
variable tags {
    default = "production"
}

# managed disk path
variable "source_vhd_path" {
    default = ""
}

# network configuration
# existing resource group name
# leave this empty if you would like to create a vnet, subnet and public IP
variable "rg" {
    default = ""
}

# existing vnet name
# leave this empty if you would like to create a vnet, subnet and public IP; requiered if resource group is defined
variable "vnet" {
    default = ""
}

# existing subnet name
# leave this empty if you would like to create a vnet, subnet and public IP; requiered if resource group and vnet are defined
variable "subnet" {
    default = ""
}

# Static IP
# leave this empty if you would like to create a vnet, subnet and public IP; requiered if resource group, subnet, vnet are defined
variable "ip" {
    default = ""
}

# skip this if you defined an existing subnet
# source IP addresses for iDNA Applications access
variable source_address_prefixes {
    type    = list
    default = ["127.0.0.1"]
}
