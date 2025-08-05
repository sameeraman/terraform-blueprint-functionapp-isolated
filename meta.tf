module "naming" {
  source              = "github.com/sameeraman/terraform-azurerm-naming"
  company-prefix      = var.company_prefix
  region-prefix       = var.location_prefix
  environment-prefix  = var.environment_prefix
}


data "azurerm_virtual_network" "hub_vnet" {
  name                = var.vnet_name
  resource_group_name = var.vnet_rg_name
}

locals {

    
}

data "azurerm_client_config" "current" {}