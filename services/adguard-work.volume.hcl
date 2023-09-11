id        = "adguard-work"
name      = "adguard-work"
type      = "csi"
plugin_id = "nfs"

capability {
  access_mode     = "multi-node-multi-writer"
  attachment_mode = "file-system"
}

parameters {
  mode = "755"
}
