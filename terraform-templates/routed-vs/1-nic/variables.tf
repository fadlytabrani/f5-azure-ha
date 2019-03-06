# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define secrets as environment variables.
# ---------------------------------------------------------------------------------------------------------------------
#
# Azure subscription details.
# TF_VAR_AZ_SUBSCRIPTION_ID
# TF_VAR_AZ_TENANT_ID
# 
# F5 BIG-IP virtual machine credentials.
# TF_VAR_F5_USERNAME
# TF_VAR_F5_PASSWORD
#
#
# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------
variable "AZ_SUBSCRIPTION_ID" {}
variable "AZ_TENANT_ID" {}
variable "AZ_REGION" {
  default = "Australia East"
}
variable "F5_USERNAME" {
  default = "f5admin"
}
variable "F5_PASSWORD" {
  default = "changethis1please!"
}
variable "objectname_prefix" {
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
