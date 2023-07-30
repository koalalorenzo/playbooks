job "archivebox_update_cron" {
  datacenters = ["dc1"]
  type = "batch"

  periodic {
    cron = "45 6 * * 6"
  }
  group "weekly" {
    volume "archivebox" {
      type = "host"
      read_only = true
      source = "archivebox"
    }

    
    task "archivebox" {
      driver = "docker"

      config {
        image        = "archivebox/archivebox:latest"
        args = [
          "add", 
          "https://getpocket.com/users/koalalorenzo/feed/all", 
          "--depth=1", "--update"
        ]
      }

      volume_mount {
        volume      = "archivebox"
        destination = "/data"
        read_only = false
      }

      resources {
        cpu = 500
        memory = 512
      }
    }
  }
}

