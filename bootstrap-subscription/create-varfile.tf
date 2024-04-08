locals {
  var_file = <<-EOT
    org="${var.org}"
    repo="${var.repo}"
  EOT
}

resource "local_file" "var_file" {
  # Generate the conf file for the remote state backend
  filename = "variables.tfvars"
  content  = local.var_file
}
