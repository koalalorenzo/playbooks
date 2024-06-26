id        = "downloads"
name      = "downloads"
type      = "csi"
plugin_id = "nfs"

capability {
  access_mode     = "multi-node-multi-writer"
  attachment_mode = "file-system"
}

parameters {
  server           = "100.100.180.12"
  share            = "/main/downloads"
  mountPermissions = "0"
}

mount_options {
  fs_type     = "nfs"
  mount_flags = ["timeo=300", "hard", "nolock"]
}
