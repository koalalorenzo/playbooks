
# Content of services/n8n.volume.hcl

id        = "n8n"
name      = "n8n"
type      = "csi"
plugin_id = "nfs"

capability {
  access_mode     = "multi-node-multi-writer"
  attachment_mode = "file-system"
}

parameters {
  server           = "100.100.180.12"
  share            = "/main/share/"
  mountPermissions = "0"
}

mount_options {
  fs_type     = "nfs"
  mount_flags = ["timeo=600", "hard", "intr", "nolock"]
}
