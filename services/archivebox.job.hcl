job "archivebox" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  update {
    min_healthy_time = "30s"
  }

  group "archivebox" {
    network {
      port "http" {
        to = 8000
      }
    }

    volume "archivebox" {
      type            = "csi"
      source          = "archivebox"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    service {
      name = "archivebox"
      port = "http"

      # check {
      #   name     = "http_login"
      #   type     = "http"
      #   port     = "http"
      #   path     = "/admin/login"
      #   interval = "120s"
      #   timeout  = "60s"
      # }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.http.rule=Host(`archive.elates.it`)",
        "traefik.http.routers.http.tls.certresolver=letsencrypt",
      ]
    }

    task "archivebox" {
      driver = "docker"

      config {
        image              = "archivebox/archivebox:latest"
        image_pull_timeout = "10m"

        ports = ["http"]
      }

      volume_mount {
        volume      = "archivebox"
        destination = "/data"
      }

      resources {
        memory = 256
      }
    }
  }
}
