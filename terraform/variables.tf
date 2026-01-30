variable "proxmox_endpoint" {
  description = "Proxmox API endpoint URL"
  type        = string
}

variable "proxmox_username" {
  description = "Proxmox API username"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox API password"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification for Proxmox API"
  type        = bool
  default     = true
}

variable "proxmox_ssh_username" {
  description = "SSH username for Proxmox host"
  type        = string
  default     = "root"
}

variable "proxmox_node" {
  description = "Proxmox node name where VM will be created"
  type        = string
}

variable "vm_name" {
  description = "Name of the MinIO VM"
  type        = string
  default     = "minio-backup"
}

variable "vm_id" {
  description = "Proxmox VM ID"
  type        = number
  default     = 500
}

variable "vm_cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "vm_cpu_type" {
  description = "CPU type"
  type        = string
  default     = "host"
}

variable "vm_memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "vm_disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 300
}

variable "vm_disk_ssd" {
  description = "Enable SSD emulation"
  type        = bool
  default     = true
}

variable "vm_storage" {
  description = "Storage pool for VM disk"
  type        = string
  default     = "longhorn-storage"
}

variable "vm_network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "vm_network_tag" {
  description = "VLAN tag (0 for no VLAN)"
  type        = number
  default     = 0
}

variable "vm_ip_address" {
  description = "Static IP address (CIDR notation, e.g., 192.168.2.100/24)"
  type        = string
}

variable "vm_gateway" {
  description = "Default gateway"
  type        = string
  default     = "192.168.2.1"
}

variable "vm_dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "cloud_init_storage" {
  description = "Storage pool for cloud-init disk (can be block storage like local-lvm)"
  type        = string
  default     = "longhorn-storage"
}

variable "snippet_storage" {
  description = "Storage pool for cloud-init snippets (must support snippets, e.g., 'local')"
  type        = string
  default     = "local"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "minio_root_user" {
  description = "MinIO root username"
  type        = string
  default     = "admin"
}

variable "minio_root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
}
