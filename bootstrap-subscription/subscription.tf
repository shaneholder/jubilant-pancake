
data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

resource "random_string" "prefix" {
  length  = 16
  special = false
}

resource "random_pet" "unique_name" {

}

resource "azurerm_resource_group" "rg" {
  name     = random_pet.unique_name.id
  location = var.location
}

resource "azurerm_storage_account" "terraform_state" {
  name                     = format("%s", lower(random_string.prefix.id))
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "plans" {
  name                  = "plans"
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}

resource "azurerm_role_definition" "example" {
  # Custom role to limit read only environments access to modify the state files
  # Read only should not need to modify, but upon init they may need to create 
  # the state file
  name        = "Terraform Read Only"
  description = "Read only role for Terraform but allow Create access on continer this is so that the plan can run which will create a state file if it does not exist"

  scope = data.azurerm_subscription.primary.id

  permissions {
    actions = [
      # "Microsoft.Storage/storageAccounts/blobServices/containers/delete",
      # "Microsoft.Storage/storageAccounts/blobServices/containers/read",
      # "Microsoft.Storage/storageAccounts/blobServices/containers/write",
      # "Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action"
    ]
    data_actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/add/action"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id,
  ]
}

resource "azuread_application" "environment" {
  for_each     = local.environments
  display_name = each.key
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "environment" {
  for_each  = azuread_application.environment
  client_id = each.value.client_id
}

resource "azuread_application_federated_identity_credential" "environment_cred" {
  for_each       = azuread_application.environment
  application_id = each.value.id
  display_name   = "my-repo-deploy"
  description    = "Deployments for my-repo"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = format("repo:%s/%s:environment:%s", var.org, var.repo, each.key)
}

resource "azurerm_role_assignment" "storage_contributor" {
  # Regular environments get contributor on the container for state files
  for_each             = { for k, v in local.environments : k => v if !v.readonly }
  scope                = azurerm_storage_container.tfstate.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.environment[each.key].object_id
}

resource "azurerm_role_assignment" "subscription_contributor" {
  # Regular environments get contributor on the subscription
  for_each             = { for k, v in local.environments : k => v if !v.readonly }
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.environment[each.key].object_id
}

resource "azurerm_role_assignment" "subscription_reader" {
  # Read Only Envs get Reader
  for_each             = { for k, v in local.environments : k => v if v.readonly }
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.environment[each.key].object_id
}

resource "azurerm_role_assignment" "terraform_readonly_tfstate" {
  # Read only environments get the custom permission
  for_each           = { for k, v in local.environments : k => v if v.readonly }
  scope              = azurerm_storage_container.tfstate.resource_manager_id
  role_definition_id = azurerm_role_definition.example.role_definition_resource_id
  principal_id       = azuread_service_principal.environment[each.key].object_id
}

resource "azurerm_role_assignment" "terraform_contrib_plans" {
  # All environments get contributor on the plan container
  for_each             = local.environments
  scope                = azurerm_storage_container.plans.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.environment[each.key].object_id
}

