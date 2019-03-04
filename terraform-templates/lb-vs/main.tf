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
