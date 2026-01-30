# Download Ubuntu Cloud Image (if not exists)
resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.proxmox_node
  url          = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  
  overwrite           = false
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_vm" "minio" {
  name        = var.vm_name
  description = "MinIO S3-compatible storage for Longhorn backups"
  node_name   = var.proxmox_node
  vm_id       = var.vm_id
  
  on_boot = true
  started = true
  
  machine = "q35"
  
  cpu {
    cores = var.vm_cpu_cores
    type  = var.vm_cpu_type
  }
  
  memory {
    dedicated = var.vm_memory
  }
  
  disk {
    datastore_id = var.vm_storage
    interface    = "scsi0"
    size         = var.vm_disk_size
    file_format  = "raw"
    discard      = "on"
    ssd          = var.vm_disk_ssd
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
  }
  
  network_device {
    bridge  = var.vm_network_bridge
    vlan_id = var.vm_network_tag != 0 ? var.vm_network_tag : null
  }
  
  operating_system {
    type = "l26"
  }
  
  agent {
    enabled = true
    timeout = "5m"  # Wait max 5min for guest agent
  }
  
  # Cloud-init configuration
  initialization {
    datastore_id = var.cloud_init_storage
    
    ip_config {
      ipv4 {
        address = var.vm_ip_address
        gateway = var.vm_gateway
      }
    }
    
    dns {
      servers = var.vm_dns_servers
    }
    
    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
    
    user_data_file_id = proxmox_virtual_environment_file.cloud_init_user_data.id
  }
  
  lifecycle {
    ignore_changes = [
      started,
    ]
  }
}

# Cloud-init user data for MinIO setup
resource "proxmox_virtual_environment_file" "cloud_init_user_data" {
  content_type = "snippets"
  datastore_id = var.snippet_storage
  node_name    = var.proxmox_node
  
  source_raw {
    data = <<-EOF
    #cloud-config
    users:
      - name: ubuntu
        groups: sudo
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - ${var.ssh_public_key}
    package_update: true
    package_upgrade: true
    packages:
      - qemu-guest-agent
      - docker.io
      - docker-compose
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - systemctl enable docker
      - systemctl start docker
      - mkdir -p /mnt/minio-data
      - |
        docker run -d \
          --name minio \
          --restart unless-stopped \
          -p 9000:9000 \
          -p 9001:9001 \
          -v /mnt/minio-data:/data \
          -e MINIO_ROOT_USER=${var.minio_root_user} \
          -e MINIO_ROOT_PASSWORD=${var.minio_root_password} \
          minio/minio server /data --console-address ":9001"
    EOF
    
    file_name = "minio-cloud-init.yaml"
  }
}
