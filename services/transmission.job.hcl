job "transmission" {
  type = "service"

  constraint {
    attribute = node.class
    value     = "compute"
  }

  constraint {
    attribute = meta.vpn.enabled
    value     = "true"
  }

  group "transmission" {
    network {
      port "http" { to = 9091 }
      port "torrent" {}
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
