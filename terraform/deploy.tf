# NOTE: Team name can only consist of lowercase letters/numbers + must be between 3-24 characters long
#
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.44.1"
    }
  }
  required_version = ">= 0.10.0"
}

data "http" "local-pubip-html" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  local_pubip = chomp(data.http.local-pubip-html.response_body)
}

locals {
  ssh_source_ips  = ["X.X.X.X", local.local_pubip]
}

module "vm" {
  source                  = "./modules/azure/vm"
  location                = "westeurope"
  icount                  = "1"
  size                    = "Standard_B2s"
  username                = "<username>"
  subid                   = "<subscription_id>"
  engagement_code         = "<engagement_code>"
  project                 = "azurevm"
  owner                   = "<email>"
  team                    = "<team_name>"
  env                     = "<environment>"
  disk_size               = "128"
  count_pip               = 1
  ssh_allow_ips           = local.ssh_source_ips
  deploy_ip               = local.local_pubip
}
output "module-vm" {
  value =  module.vm
}


