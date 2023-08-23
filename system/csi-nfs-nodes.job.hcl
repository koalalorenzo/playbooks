# From: https://gitlab.com/rocketduck/csi-plugin-nfs
job "nfs-storage-node" {
  datacenters = ["dc1"]
  type        = "system"
  priority    = 100

  group "node" {
    restart {
      # Restart every 30 seconds for 3 times, and then wait 1 min to try again
      delay    = "15s"
      interval = "60s"
      attempts = 4
      mode     = "delay" # try again, never fail
    }

    task "node" {
      driver = "docker"

      config {
        image = "registry.gitlab.com/rocketduck/csi-plugin-nfs:0.7.0"

        args = [
          "--type=node",
          "--node-id=${attr.unique.hostname}",
          "--nfs-server=192.168.197.125:/main/nfs",
          "--mount-options=defaults",
          "--allow-nested-volumes",
          "--log-level=DEBUG",
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
        memory = 128
      }

    }
  }
}
