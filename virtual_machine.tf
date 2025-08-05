# Provision VM
module "virtual_machine" {
  source   = "github.com/sameeraman/terraform-azurerm-virtual-machine"

  virtual_machine_name       = join("", [module.naming.virtual_machine.name, "ai1"])
  virtual_machine_rg_name    = module.rg1.name
  location                   = var.location
  virtual_network_rg_name    = var.vnet_rg_name
  virtual_network_name       = var.vnet_name
  subnet_name                = var.vnet_subnet_name
  admin_password             = var.vm_password
  virtual_machine_os         = "windows" # windows or linux
  activate_ahb               = true
  enable_public_ip           = false

  tags = var.tags

  depends_on = [module.rg1]

}
