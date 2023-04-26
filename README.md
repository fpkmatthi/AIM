# AIM

**A**zure **I**nstant **V**M

Basic idempotent infra to deploy a single VM in azure with a security-by-design configuration. Used when you need a quick Linux environment for testing.


## Current build

- Terraform infra configuration is located in `./terraform/deploy.tf`
- Ansible configuration is located in `./ansible/site.yml`

## Prerequisites

Install:
- Terraform
- Ansible
- Azure-cli

Debian derivatives:
```bash
sudo apt install terraform ansible  python3 python3-pip
pip3 install azure-cli --user
```

Arch:
```bash
sudo pacman -S terraform ansible
yay -S azure-cli
```

Login on Azure and set your subscription:
```bash
az login
az account set --subscription <id>
```

## Configuration

Change the necessary variables to alter the config in the following locations:
- ./terraform/deploy.yml 
- ./ansible/vm.yml

By default, you can connect from the pub ip from where you deploy the infra and from the SECNET VPN.

You can add custom ansible roles by installing them from Ansible-Galaxy or putting them in ./ansible/roles and changing ./ansible/vm.yml and the group_vars files accordingly.

Ensure your SSH pubkey is in the Ansible-Vault files:
```
ansible-vault edit ./ansible/group_vars/vault.yml
ansible-vault edit ./ansible/group_vars/vm/vault.yml
```
**NOTE**: you can put the Ansible-Vault pw in a dotfile in the root dir of this repo and export it as a shell variable to automatically use it when provisioning with Ansible. (The current pw is the EY backtrack pw)

## Automated

Execute the following commands in the root dir to deploy the infra:

1. `make plan`
2. `make deploy`
3. `make provision`

To destroy the infra, execute the following command:

1. `make destoy`

## Manual (debugging)

```bash
cd ./terraform
terraform plan -out tfplan
terraform apply tfplan
./tf-parse-ips.py > ../ansible/inventory
cd ../ansible
ansible-playbook -i inventory site.yml
```

## Clean up

1. Run `make destroy`

