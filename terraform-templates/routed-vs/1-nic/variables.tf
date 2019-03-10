variable azure_subscription_id {}
variable azure_tenant_id {}
variable azure_region {}

variable "f5_username" {}
variable "f5_license_keys" {
  type = "list"
}
variable "f5_password" {}
variable "name_prefix" {
  default = "f5ha"
}

variable "vm_size" {
  default = "Standard_F8s_v2"
}
variable "f5_version" {
  default = "14.1.001000"
}
variable "vnet_address_space" {
  default = ["10.4.0.0/16"]
}
variable "interfaces" {
  default = [
    "external"
  ]
}
variable "interface_subnets" {
  default = [
    "10.4.0.0/23"
  ]
}
variable "routed_subnets" {
   default = [
    "10.4.10.0/24"
  ]
}