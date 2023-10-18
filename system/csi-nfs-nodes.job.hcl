job "csi-nfs-node" {
  type     = "system"
  priority = 100

  group "node" {
    restart {
      delay    = "15s"
      interval = "60s"
      attempts = 4
      mode     = "delay" # try again, never fail
    }

    task "node" {
      driver = "docker"

      config {
        image = "registry.k8s.io/sig-storage/nfsplugin:v4.4.0"

        args = [
          "--v=5",
          "--nodeid=${attr.unique.hostname}",
          "--endpoint=unix:///csi/csi.sock",
          "--drivername=nfs.csi.k8s.io"
        ]

        network_mode = "host"
        privileged   = true
      }

      csi_plugin {
        id        = "nfs"
        type      = "node"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 100
        memory = 32
      }
    }
  }
}
