data "github_repository" "repo" {
  full_name = "${var.org}/${var.repo}"
}
