id        = "restic"
name      = "restic"
type      = "csi"
plugin_id = "nfs"

capability {
  access_mode     = "multi-node-single-writer"
  attachment_mode = "file-system"
}

parameters {
  mode = "777"
}
