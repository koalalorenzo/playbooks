job "postgres" {
  type     = "service"
  priority = 80

  group "postgres" {
    affinity {
      attribute = node.class
      value     = "compute"
      weight    = 90
    }

    restart {
      attempts = 5
      interval = "30m"
      delay    = "20s"
    }

    volume "postgres" {
      type            = "csi"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      source          = "postgres"
    }

    network {
      port "postgres" { to = 5432 }
    }

    task "postgres" {
      driver         = "docker"
      user           = "1000"
      kill_signal    = "SIGTERM"
      kill_timeout   = "30s"
      shutdown_delay = "5s"

      config {
        image = "postgres:16.1-alpine"
        ports = ["postgres"]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          {{- with nomadVar "nomad/jobs/postgres" -}}
          POSTGRES_USER={{ .username }}
          POSTGRES_PASSWORD={{ .password }}
          {{- end -}}
        EOH
      }

      volume_mount {
        volume      = "postgres"
        destination = "/var/lib/postgresql/data"
        read_only   = false
      }
      
      resources {
        cpu    = 1500
        memory = 768
      }
      
      service {
        name = "postgres"
        port = "postgres"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "30s"
          timeout  = "3s"
        }
      }
    }
  }
}

