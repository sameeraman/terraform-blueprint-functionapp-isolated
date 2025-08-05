module "rg1" {
  source = "github.com/sameeraman/terraform-azurerm-resource-group"

  name     = join("-", [module.naming.resource_group.name, var.workload_postfix])
  location = var.location
  tags     = var.tags
}