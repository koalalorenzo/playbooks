# From: https://gitlab.com/rocketduck/csi-plugin-nfs
job "nfs-storage-controller" {
  datacenters = ["dc1"]
  type        = "service"
  priority = 100


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
        image = "registry.gitlab.com/rocketduck/csi-plugin-nfs:0.7.0"

        args = [
          "--type=controller",
          "--node-id=${attr.unique.hostname}",
          "--nfs-server=192.168.197.151:/main/nfs",
          "--mount-options=defaults",
          "--allow-nested-volumes",
          "--log-level=DEBUG",
        ]

        network_mode = "host" 
        privileged = true
      }

      csi_plugin {
        id        = "nfs"
        type      = "controller"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 100
        memory = 128
      }

    }
  }
}

