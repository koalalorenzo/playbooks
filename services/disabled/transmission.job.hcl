job "transmission" {
  type = "service"

  constraint {
    attribute = node.class
    value     = "compute"
  }

  group "transmission" {
    network {
      port "http" { to = 9091 }
      port "torrent" {}
    }

    volume "transmission" {
      type            = "csi"
      source          = "transmission"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    volume "downloads" {
      type            = "csi"
      source          = "downloads"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "transmission" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/transmission:latest"
        ports = ["http", "torrent"]
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
          PEERPORT={{ env "NOMAD_PORT_torrent" }}
        EOH
      }

      service {
        name = "transmission"
        port = "http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.transmission.rule=Host(`transmission.elates.it`)",
          "traefik.http.routers.transmission.tls.certresolver=letsencrypt",
        ]

      }

      volume_mount {
        volume      = "transmission"
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
