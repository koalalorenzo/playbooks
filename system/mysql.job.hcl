job "mysql" {
  type     = "service"
  priority = 80

  group "mysql" {
    affinity {
      attribute = node.class
      value     = "storage"
      weight    = 60
    }

    restart {
      attempts = 5
      interval = "30m"
      delay    = "20s"
      mode     = "delay"
    }

    volume "mysql" {
      type            = "csi"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      source          = "mysql"
    }

    network {
      port "mysql" { to = 3306 }
    }

    task "mysql" {
      driver         = "docker"
      kill_signal    = "SIGTERM"
      kill_timeout   = "30s"
      shutdown_delay = "3s"

      config {
        image = "lscr.io/linuxserver/mariadb:latest"
        ports = ["mysql"]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          PUID=1000
          PGID=1000
          TZ=Etc/UTC
          {{- with nomadVar "nomad/jobs/mysql" -}}
          MYSQL_DATABASE={{ .username }}
          MYSQL_USER={{ .username }}
          MYSQL_PASSWORD={{ .password }}
          MYSQL_ROOT_PASSWORD={{ .password }}
          {{- end -}}
        EOH
      }

      volume_mount {
        volume      = "mysql"
        destination = "/config"
        read_only   = false
      }
      
      resources {
        cpu    = 500
        memory = 256
      }
      
      service {
        name = "mysql"
        port = "mysql"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "60s"
          timeout  = "3s"
        }
      }
    }
  }
}

