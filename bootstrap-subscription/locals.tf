locals {
  l_environments = {for env in var.environments: env => {
    readonly = false
  }}

  l_environments_ro = {for env in var.environments: format("%s-ro",env) => {
    readonly = true
  }}

  environments = merge(local.l_environments, local.l_environments_ro)
}
