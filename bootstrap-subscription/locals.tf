locals {
  l_environments = { for env in var.environments : env.name => {
    readonly = false,
    approval = env.approval
  } }

  l_environments_ro = { for env in var.environments : format("%s-ro", env.name) => {
    readonly = true,
    approval = false
  } }

  environments = merge(local.l_environments, local.l_environments_ro)
}
