variable "environments" {
  type    = list(string)
  default = ["production", "development"]
}

variable "org" {
  description = "What is the github org"
  type = string
}

variable "repo" {
  description = "Name of github repository"
  type = string
}

variable "location" {
  type    = string
  default = "centralus"
}