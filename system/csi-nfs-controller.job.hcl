# From: https://gitlab.com/rocketduck/csi-plugin-nfs
job "csi-nfs-controller" {
  type     = "service"
  priority = 100

  constraint {
    attribute = node.class
    value     = "storage"
  }

  group "controller" {
    restart {
      delay    = "5s"
      interval = "5m"
      attempts = 55
      mode     = "delay"
    }


    task "nfs-controller" {
      driver = "docker"

      config {
        image = "registry.k8s.io/sig-storage/nfsplugin:v4.6.0"

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
        type      = "controller"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 100
        memory = 64
      }

    }
  }
}

