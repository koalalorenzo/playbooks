job "archivebox_update_cron" {
  datacenters = ["dc1"]
  type        = "batch"

  periodic {
    cron             = "45 6 * * *"
    prohibit_overlap = true
    time_zone        = "CET"
  }

  group "weekly" {
    volume "archivebox" {
      type            = "csi"
      source          = "archivebox"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "archivebox_update" {
      driver = "docker"

      config {
        image = "archivebox/archivebox:latest"
        args = [
          "add",
          "https://getpocket.com/users/koalalorenzo/feed/all",
          "--depth=1"
        ]
      }

      volume_mount {
        volume      = "archivebox"
        destination = "/data"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }
}

