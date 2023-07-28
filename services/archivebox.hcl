job "archivebox" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  group "archivebox" {
    network {
      port "http" {
        to = 8000
      }      
    }

    service {
      name = "archive"
      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "60s"
        timeout  = "5s"
      }
    }

    task "archivebox" {
      driver = "docker"

      config {
        image        = "archivebox/archivebox"
      }

      volume_mount {
        volume      = "downloads"
        destination = "/data"
        propagation_mode = "private"
        read_only = true
      }

      resources {
        cpu    = 150
        memory = 64
      }
    }
  }
}


