job "qbittorrent" {
  type = "service"

  constraint {
    attribute = node.class
    value     = "compute"
  }

  group "qbittorrent" {
    network {
      port "http" {}
    }

    volume "qbittorrent" {
      type            = "csi"
      source          = "qbittorrent"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    volume "downloads" {
      type            = "csi"
      source          = "downloads"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "qbittorrent" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/qbittorrent:latest"
        ports = ["http"]
      }

      restart {
        delay    = "10s"
        interval = "30s"
        attempts = 3
        mode     = "delay"
      }


      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          PGID=1000
          PUID=1000
          WEBUI_PORT={{ env "NOMAD_PORT_http" }}
        EOH
      }

      service {
        name = "qbittorrent"
        port = "http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.qbittorrent.rule=Host(`qbittorrent.elates.it`)",
          "traefik.http.routers.qbittorrent.tls.certresolver=letsencrypt",
        ]

      }

      volume_mount {
        volume      = "qbittorrent"
        destination = "/config"
      }

      volume_mount {
        volume      = "downloads"
        destination = "/downloads"
      }

      resources {
        cpu    = 1000
        memory = 512
      }
    }
  }
}
