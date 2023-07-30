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

    volume "archivebox" {
      type = "host"
      source = "archivebox"
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

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.http.rule=Host(`archive.setale.me`)",
      ]
    }

    task "archivebox" {
      driver = "docker"

      config {
        image        = "archivebox/archivebox:latest"
        image_pull_timeout = "10m"
      }

      volume_mount {
        volume      = "archivebox"
        destination = "/data"
      }

      resources {
        memory = 128
      }
    }
  }
}
