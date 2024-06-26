job "csi-nfs-node" {
  type     = "system"
  priority = 100

  group "node" {
    restart {
      delay    = "15s"
      interval = "5m"
      attempts = 20
      mode     = "delay"
    }

    task "nfs-node" {
      driver       = "docker"
      kill_timeout = "60s"

      config {
        image = "registry.k8s.io/sig-storage/nfsplugin:v4.7.0"

        args = [
          "--v=2",
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
        memory = 64
      }
    }
  }
}
