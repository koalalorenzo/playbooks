job "archivebox-update" {
  type        = "batch"

  periodic {
    cron             = "45 6 * * *"
    prohibit_overlap = true
    time_zone        = "CET"
  }

  # Prefer but not enforce to run on compute1
  affinity {
    attribute = "${attr.unique.hostname}"
    value     = "compute1"
    weight    = 100
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

