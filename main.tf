terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  pm_api_url      = "https://192.168.1.XX:8006/api2/json" # Ton IP Proxmox
  pm_api_token_id = "votre_token_id"
  pm_api_token_secret = "votre_token_secret"
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "serveurs_locaux" {
  count       = 3 # Crée 3 serveurs en parallèle
  name        = "serveur-ansible-${count.index + 1}"
  target_node = "pve" # Le nom de ton nœud Proxmox
  clone       = "ubuntu-template" # Le nom de ton template VM

  # On décale l'ID pour éviter les conflits (ex: 201, 202, 203)
  vmid        = 200 + count.index + 1

  cores   = 2
  memory  = 2048
  agent   = 1 # Indispensable pour récupérer l'IP via Ansible plus tard

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Configuration Cloud-init pour qu'Ansible puisse se connecter
  os_type = "cloud-init"
  sshkeys = "ssh-rsa TA_CLE_PUBLIQUE_ICI"
}
