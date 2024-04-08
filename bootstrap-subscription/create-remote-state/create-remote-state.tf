terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  description = "Azure Region to use."
  type = string
}

resource "random_string" "resource_code" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_resource_group" "tfstate" {
  name     = "bootstrap-tfstate"
  location = var.location
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "bootstrap${random_string.resource_code.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

locals {
  init_config = <<-EOT
    resource_group_name="${azurerm_resource_group.tfstate.name}"
    storage_account_name="${azurerm_storage_account.tfstate.name}"
    container_name="${azurerm_storage_container.tfstate.name}"
    key="init.tfstate"  
  EOT

  var_file = <<-EOT
    location="${var.location}"
  EOT
}

resource "local_file" "var_file" {
  # Generate the conf file for the remote state backend
  # This file will remain during a destroy
  filename = "variables.tfvars"
  content  = local.var_file
  lifecycle {
    prevent_destroy = true
  }
}

resource "local_file" "init_config" {
  # Generate the conf file for the remote state backend
  # This file will remain during a destroy
  filename = "../init.conf"
  content  = local.init_config
  lifecycle {
    prevent_destroy = true
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}

output "container_name" {
  value = azurerm_storage_container.tfstate.name
}