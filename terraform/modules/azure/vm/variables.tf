variable "engagement_code" {
  type    = string
  default = "E-694201337"
}

variable "icount" {
  default = 1
}

variable "disk_size" {
  type    = number
  default = 32
}
variable "location" {
  type    = string
  default = "westeurope"
}

variable "env" {
  type    = string
  default = "demo"
}

variable "team" {
  type    = string
  default = "test-team"
}

variable "owner" {
  type    = string
  default = "example@be.ey.com"
}

variable "username" {
  default = "rtadmin"
}

variable "project" {
  default = "redteam-test"
}

variable "size" {
  default = "Standard_D1_v2"
}

variable "count_pip" {
  default = 1
}

variable "locations_map" {
  type = map
  default = {
    eastus = "use"
    eastus2 = "ue2"
    centralus = "usc"
    northcentralus = "usn"
    southcentralus = "uss"
    westcentralus = "usw"
    westus = "uwu"
    westus2 = "uw2"
    canadaeast = "cae"
    canadacentral = "cac"
    brazilsouth = "brs"
    northeurope = "eun"
    westeurope = "euw"
    ukwest = "ukw"
    uksouth = "uks"
    germanynorth = "gno"
    germanywestcentra = "gwc"
    francecentral = "frc"
    francesouth = "frs"
    southeastasia = "aps"
    eastasia = "ape"
    australiaeast = "aue"
    australiasoutheas = "aus"
    australiacentral = "ac1"
    australiacentral2 = "ac2"
    centralindia = "inc"
    westindia = "inw"
    southindia = "ins"
    japaneast = "jpe"
    japanwest = "jpw"
    koreacentral = "koc"
    koreasouth = "kos"
    switzerlandnorth = "swn"
    switzerlandnorth = "sww"
    norwaywest = "now"
    norwayeast = "noe"
    southafricanorth = "zan"
    switzerlandwest = "zaw"
    uaecentral = "uac"
    uaenorth = "uan"
  }
}

variable "ssh_allow_ips" {
  type    = list
  # default = ""
}
variable "deploy_ip" {
  type    = string
  default = ""
}

