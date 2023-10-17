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
      # Restart every 30 seconds for 3 times, and then wait 1 min to try again
      delay    = "5s"
      interval = "15s"
      attempts = 3
      mode     = "delay" # try again, never fail
    }


    task "controller" {
      driver = "docker"

      config {
        image = "registry.k8s.io/sig-storage/nfsplugin:v4.4.0"

        args = [
          "--v=5",
          "--nodeid=${attr.unique.hostname}",
          "--endpoint=unix:///csi/csi.sock",
          "--drivername=nfs.csi.k8s.io"
        ]
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

