job "vrising" {
  type = "service"

  group "vrising" {
    constraint {
      attribute = node.class
      value     = "compute"
    }

    constraint {
      attribute = attr.cpu.arch
      value     = "amd64"
    }

    network {
      port "steamfifteen" { static = 27015 }
      port "steamsixteen" { static = 27016 }
      port "game" { static = 9876 }
      port "query" { static = 9877 }
      port "rcon" { static = 25575 }
    }


    restart {
      delay    = "10s"
      interval = "30s"
      attempts = 3
      mode     = "delay"
    }

    task "gameserver" {
      driver       = "docker"
      kill_timeout = "65s"

      config {
        image = "trueosiris/vrising:2.1"
        network_mode = "host"

        ports = [
          "game",
          "query",
        ]
      }

      volume_mount {
        volume      = "vrising"
        destination = "/mnt/vrising/persistentdata"
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          SERVERNAME="Pan Rising"
          LOGDAYS=3
        EOH
      }

      resources {
        cpu    = 4000  # 4 Ghz
        memory = 8192 # 8 GB
      }

      service {
        name = "vrising"
        port = "rcon"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.vrising.rule=Host(`vrising.elates.it`) || Host(`vrising.ts.elates.it`)",
          "traefik.http.routers.vrising.tls.certresolver=letsencrypt",
        ]
      }
    }

    volume "vrising" {
      type            = "csi"
      source          = "vrising"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }
  }
}
