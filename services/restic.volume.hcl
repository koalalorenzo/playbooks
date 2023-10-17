id        = "restic"
name      = "restic"
type      = "csi"
plugin_id = "nfs"

capability {
  access_mode     = "multi-node-single-writer"
  attachment_mode = "file-system"
}

parameters {
  server           = "storage0"
  share            = "/main/share/"
  mountPermissions = "0"
}

mount_options {
  fs_type     = "nfs"
  mount_flags = ["timeo=600", "hard", "intr", "nolock"]
}
