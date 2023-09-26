id        = "redis"
name      = "redis"
type      = "csi"
plugin_id = "nfs"

capability {
  access_mode     = "single-node-writer"
  attachment_mode = "file-system"
}

parameters {
  mode = "755"
}
