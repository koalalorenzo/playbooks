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
      mode = "host"
      port "steamfifteen" {
        static = 27015
      }

      port "steamsixteen" {
        static = 27016
      }

      port "game" {
        static = 9876
      }
      port "query" {
        static = 9877
      }
      port "rcon" {
        static = 25575
      }
    }


    restart {
      delay    = "10s"
      interval = "30s"
      attempts = 3
      mode     = "delay"
    }

    task "vrising" {
      driver       = "docker"
      kill_timeout = "65s"

      config {
        image        = "trueosiris/vrising:2.1"
        network_mode = "host"

        ports = [
          "game",
          "query",
        ]

        labels {
          persist_logs = "true"
        }
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
        memory = 12288 # 12 GB
      }

      service {
        name = "vrising-rcon"
        port = "rcon"
      }

      service {
        name = "vrising"
        port = "steamfifteen"
      }
    }

    volume "vrising" {
      type   = "host"
      source = "vrising"
    }
  }
}
