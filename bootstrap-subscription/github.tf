resource "github_repository_environment" "repo_environment" {
  for_each    = toset(var.environments)
  repository  = data.github_repository.repo.name
  environment = each.key
}

resource "github_repository_environment" "repo_environment-ro" {
  for_each    = toset(var.environments)
  repository  = data.github_repository.repo.name
  environment = "${each.key}-ro"
}

resource "github_actions_environment_variable" "client_id" {
  for_each      = github_repository_environment.repo_environment
  repository    = data.github_repository.repo.name
  environment   = each.value.environment
  variable_name = "AZURE_CLIENT_ID"
  value         = azuread_application.environment[each.key].client_id
}

resource "github_actions_environment_variable" "storage_account_resource_group" {
  for_each      = merge (tomap(github_repository_environment.repo_environment), tomap(github_repository_environment.repo_environment-ro))
  repository    = data.github_repository.repo.name
  environment   = each.value.environment
  variable_name = "TF_VAR_resource_group_name"
  value         = azurerm_resource_group.rg.name
}

resource "github_actions_environment_variable" "storage_account" {
  for_each      = merge (tomap(github_repository_environment.repo_environment), tomap(github_repository_environment.repo_environment-ro))
  repository    = data.github_repository.repo.name
  environment   = each.value.environment
  variable_name = "TF_VAR_storage_account_name"
  value         = azurerm_storage_account.terraform_state.name
}

resource "github_actions_environment_variable" "client_id_ro" {
  for_each      = github_repository_environment.repo_environment
  repository    = data.github_repository.repo.name
  environment   = format("%s-ro", each.value.environment)
  variable_name = "AZURE_CLIENT_ID"
  value         = azuread_application.environment-ro[each.value.environment].client_id
}

resource "github_actions_variable" "subscription_id" {
  repository    = data.github_repository.repo.name
  variable_name = "AZURE_SUBSCRIPTION_ID"
  value         = data.azurerm_subscription.primary.subscription_id
}

resource "github_actions_variable" "tenant_id" {
  repository    = data.github_repository.repo.name
  variable_name = "AZURE_TENANT_ID"
  value         = data.azurerm_subscription.primary.tenant_id
}
