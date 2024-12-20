resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = format("%s_%s", random_pet.rg_name.id, var.environment)
}

# release
# feature 1
# feature 2