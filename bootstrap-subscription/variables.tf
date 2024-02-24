variable "environments" {
  type = list(string)
  default = ["production", "development"]
}

variable "org" {
  type = string
}

variable "repo" {
  type = string  
}

variable "location" {
  type = string
  default = "centralus"
}