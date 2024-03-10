variable "environments" {
  type    = list(object({
    name = string,
    approval = bool
  }))
  default = [
    {
      name = "production",
      approval = true
    },
    {
      name = "development",
      approval = false
    }
  ]
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