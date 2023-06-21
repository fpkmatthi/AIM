provider "azurerm" {
  subscription_id = var.subid
  features {}
  skip_provider_registration = true
}

resource "random_id" "rand" {
  byte_length = 4
}

resource "azurerm_resource_group" "rg" {
  count    = var.icount
  location = var.location
  name     = "rg-p-${var.locations_map[var.location]}-${var.team}-${var.project}-vm-${count.index}-${random_id.rand.hex}"

  tags = {
    project = var.project
    environment = var.env
    team = var.team
    owner = var.owner
    engagement_code = var.engagement_code
  }
}

resource "azurerm_storage_account" "sa" {
  count                    = var.icount
  name                     = "st${var.project}${count.index}${random_id.rand.hex}"
  resource_group_name      = element(azurerm_resource_group.rg.*.name, count.index)
  location                 = element(azurerm_resource_group.rg.*.location, count.index)
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    project = var.project
    environment = var.env
    team = var.team
    owner = var.owner
    engagement_code = var.engagement_code
  }
}

resource "azurerm_storage_container" "sc" {
  count                 = var.icount
  name                  = "sc${var.project}-vhds"
  storage_account_name  = element(azurerm_storage_account.sa.*.name, count.index)
#  resource_group_name   = element(azurerm_resource_group.rg.*.name, count.index)
  container_access_type = "private"
}

resource "tls_private_key" "ssh" {
  count     = var.icount
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_network_security_group" "nsg" {
  count               = var.icount
  name                = "nsg-${var.project}-vm-allowall-${count.index}"
  location            = element(azurerm_resource_group.rg.*.location, count.index)
  resource_group_name = element(azurerm_resource_group.rg.*.name, count.index)

  security_rule {
    name                       = "All-In"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

#   security_rule {
#     name                       = "SSH"
#     priority                   = 1001
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefixes    = "${var.ssh_allow_ips}"
#     destination_address_prefix = "*"
#   }

  tags = {
    project = var.project
    environment = var.env
    team = var.team
    owner = var.owner
    engagement_code = var.engagement_code
  }
}

resource "azurerm_virtual_network" "vnet" {
  count               = var.icount
  name                = "vnet-${var.project}-vm-${count.index}"
  address_space       = ["10.0.0.0/8"]
  location            = element(azurerm_resource_group.rg.*.location, count.index)
  resource_group_name = element(azurerm_resource_group.rg.*.name, count.index)

  tags = {
    project = var.project
    environment = var.env
    team = var.team
    owner = var.owner
    engagement_code = var.engagement_code
  }
}

resource "azurerm_subnet" "subnet" {
  count                = var.icount
  name                 = "snet-${var.project}-vm-${count.index}"
  resource_group_name  = element(azurerm_resource_group.rg.*.name, count.index)
  virtual_network_name = element(azurerm_virtual_network.vnet.*.name, count.index)
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_public_ip" "pip" {
  count                        = var.icount * 1
  name                         = "pip-${var.project}-vm-${floor(count.index / 1)}-${count.index % 1}"
  location                     = element(azurerm_resource_group.rg.*.location, floor(count.index/1))
  resource_group_name          = element(azurerm_resource_group.rg.*.name, floor(count.index/1))
  allocation_method            = "Static"

  tags = {
    project = var.project
    environment = var.env
    team = var.team
    owner = var.owner
    engagement_code = var.engagement_code
  }
}

resource "azurerm_network_interface_security_group_association" "nicnsg" {
  network_interface_id      = azurerm_network_interface.nic[0].id
  network_security_group_id = azurerm_network_security_group.nsg[0].id
}

resource "azurerm_network_interface" "nic" {
  count                     = var.icount
  name                      = "nic-${var.project}-vm-${count.index}-0"
  location                  = element(azurerm_resource_group.rg.*.location, count.index)
  resource_group_name       = element(azurerm_resource_group.rg.*.name, count.index)
#  network_security_group_id = element(azurerm_network_security_group.nsg.*.id, count.index)

    ip_configuration {
    name                          = "niccfg-${var.project}-vm-${count.index}-0"
    subnet_id                     = element(azurerm_subnet.subnet.*.id, count.index)
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.pip.*.id, (count.index*1)+0)
        primary                       = true
      }
  
  tags = {
    project = var.project
    environment = var.env
    team = var.team
    owner = var.owner
    engagement_code = var.engagement_code
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                 = var.icount
  name                  = "${var.project}-vm-${count.index}"
  location              = element(azurerm_resource_group.rg.*.location, count.index)
  resource_group_name   = element(azurerm_resource_group.rg.*.name, count.index)
  network_interface_ids = [element(azurerm_network_interface.nic.*.id, count.index)]
  size                  = var.size

  # Official Debian images for Azure: https://wiki.debian.org/Cloud/MicrosoftAzure
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal-daily"
    sku       = "20_04-daily-lts"
    version   = "latest"
  }

  os_disk {
    name                   = "osdisk-${var.project}-vm-${count.index}-0"
    caching                = "ReadWrite"
    storage_account_type   = "Premium_LRS"
    disk_encryption_set_id = azurerm_disk_encryption_set.disk-encryption-set.id
  }

  admin_username                  = var.username
  computer_name                   = "${var.project}-vm-${count.index}"
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.username
    public_key = element(tls_private_key.ssh.*.public_key_openssh, count.index)
  }


  provisioner "local-exec" {
    command = "echo \"${element(tls_private_key.ssh.*.private_key_pem, count.index)}\" > ../ssh_keys/${var.project}-vm-${count.index} && echo \"${element(tls_private_key.ssh.*.public_key_openssh, count.index)}\" > ../ssh_keys/${var.project}-vm-${count.index}.pub && chmod 400 ../ssh_keys/${var.project}-vm-${count.index}*"

  }

  

  # provisioner "local-exec" {
  #   when    = destroy
  #   command = "rm ../ssh_keys/vm-${count.index}* | tee -a ../terraform.log"
  # }

  # Not needed for Ubuntu - uncomment if Debian
  # 
  tags = {
    project = var.project
    environment = var.env
    team = var.team
    owner = var.owner
    engagement_code = var.engagement_code
  }
}

data "azurerm_client_config" "current" {}
data "azurerm_platform_image" "osimage" {
  location  = azurerm_resource_group.rg.0.location
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-focal-daily"
  sku       = "20_04-daily-lts"
  }

resource "azurerm_key_vault" "keyvault" {
  name                        = "kv-${var.project}${random_id.rand.hex}"
  location                    = azurerm_resource_group.rg.0.location
  resource_group_name         = azurerm_resource_group.rg.0.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = true
# soft_delete_enabled         = true
  purge_protection_enabled    = true
  sku_name                    = "standard"

  tags = {
    project = var.project
    environment = var.env
    team = var.team
    owner = var.owner
    engagement_code = var.engagement_code
  }
}

resource "azurerm_key_vault_key" "keyvault-key" {
  name         = "key-${var.project}-vm"
  key_vault_id = azurerm_key_vault.keyvault.id
  key_type     = "RSA"
  key_size     = 2048

  depends_on = [
    azurerm_key_vault_access_policy.keyvault-policy-user
  ]

  # rotation_policy {
  #   automatic {
  #     time_before_expiry = "P30D"
  #   }

  #   expire_after         = "P90D"
  #   notify_before_expiry = "P29D"
  # }

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_disk_encryption_set" "disk-encryption-set" {
  name                = "des-${var.project}-vm"
  location            = azurerm_resource_group.rg.0.location
  resource_group_name = azurerm_resource_group.rg.0.name
  key_vault_key_id    = azurerm_key_vault_key.keyvault-key.id

  identity {
    type = "SystemAssigned"
  }

  tags = {
    project = var.project
    environment = var.env
    team = var.team
    owner = var.owner
    engagement_code = var.engagement_code
  }
}

resource "azurerm_key_vault_access_policy" "keyvault-policy-disk" {
  key_vault_id = azurerm_key_vault.keyvault.id

  tenant_id = azurerm_disk_encryption_set.disk-encryption-set.identity.0.tenant_id
  object_id = azurerm_disk_encryption_set.disk-encryption-set.identity.0.principal_id

  key_permissions = [
    "Get",
    "Decrypt",
    "Encrypt",
    "Sign",
    "UnwrapKey",
    "Verify",
    "WrapKey",
  ]
}

resource "azurerm_key_vault_access_policy" "keyvault-policy-user" {
  key_vault_id = azurerm_key_vault.keyvault.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey",
    "Create",
    "Delete",
    "List"
  ]
}


resource "azurerm_managed_disk" "vm-data" {
  count                = var.icount
  name                 = "disk-${var.project}-vm-${count.index}-data-0"
  location             = element(azurerm_resource_group.rg.*.location, count.index)
  resource_group_name  = element(azurerm_resource_group.rg.*.name, count.index)
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.disk_size

    disk_encryption_set_id = azurerm_disk_encryption_set.disk-encryption-set.id
  
  tags = {
    project = var.project
    environment = var.env
    team = var.team
    owner = var.owner
    engagement_code = var.engagement_code
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm" {
  count              = var.icount
  managed_disk_id    = element(azurerm_managed_disk.vm-data.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.vm.*.id, count.index)
  lun                = "10"
  caching            = "ReadWrite"
}
