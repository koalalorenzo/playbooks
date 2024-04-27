id        = "7d2d-serverfiles"
name      = "7d2d-serverfiles"
type      = "csi"
plugin_id = "nfs"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}

parameters {
  server           = "100.100.180.12"
  share            = "/main/share/7d2d/"
  mountPermissions = "0"
}

mount_options {
  fs_type     = "nfs"
  mount_flags = ["timeo=600", "hard", "intr", "nolock", "nosharecache", "fsc"]
}
