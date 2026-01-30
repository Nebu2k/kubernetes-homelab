output "vm_id" {
  description = "MinIO VM ID"
  value       = proxmox_virtual_environment_vm.minio.vm_id
}

output "vm_name" {
  description = "MinIO VM name"
  value       = proxmox_virtual_environment_vm.minio.name
}

output "vm_ip_address" {
  description = "MinIO VM IP address"
  value       = var.vm_ip_address
}

output "minio_api_endpoint" {
  description = "MinIO API endpoint (S3-compatible)"
  value       = "http://${split("/", var.vm_ip_address)[0]}:9000"
}

output "minio_console_url" {
  description = "MinIO Console URL"
  value       = "http://${split("/", var.vm_ip_address)[0]}:9001"
}

output "connection_info" {
  description = "Connection information"
  value = <<-EOT
  
  MinIO VM deployed successfully!
  
  SSH Access:
    ssh ubuntu@${split("/", var.vm_ip_address)[0]}
  
  MinIO Console:
    URL: http://${split("/", var.vm_ip_address)[0]}:9001
    User: ${var.minio_root_user}
    
  MinIO S3 API:
    Endpoint: http://${split("/", var.vm_ip_address)[0]}:9000
    
  Longhorn Backup Target:
    s3://homelab-longhorn@us-east-1/
    AWS_ENDPOINT: http://${split("/", var.vm_ip_address)[0]}:9000
  EOT
}
