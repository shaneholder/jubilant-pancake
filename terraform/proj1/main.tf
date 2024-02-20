resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  count    = 1
  location = var.resource_group_location
  name     = format("%s_%s_%s", random_pet.rg_name.id, count.index, var.environment)
}
