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
      port "steamfifteen" { to = 27015 }
      port "steamsixteen" { to = 27016 }
      port "game" { }
      port "query" { }
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
        destination = "/mnt/vrising/"
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          SERVERNAME="pan-rising"
          GAMEPORT={{ env `NOMAD_PORT_game` }}
          QUERYPORT={{ env `NOMAD_PORT_query` }}
          LOGDAYS=3
        EOH
      }

      resources {
        cpu    = 2000  # 2 Ghz
        memory = 4096 # 4 GB
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
