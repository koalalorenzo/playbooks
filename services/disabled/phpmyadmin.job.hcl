job "phpmyadmin" {
  type = "service"

  group "phpmyadmin" {
    constraint {
      attribute = node.class
      value     = "compute"
    }

    network {
      port "phpmyadmin" { to = 80 }
    }

    restart {
      delay    = "10s"
      interval = "30s"
      attempts = 3
    }

    task "phpmyadmin" {
      driver = "docker"

      config {
        image = "phpmyadmin:latest"
        ports = ["phpmyadmin"]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          {{ range service "postgres" }}
          PMA_HOST={{ .Address }}
          PMA_PORT={{ .Port }}
          {{ end }}
          {{- with nomadVar "nomad/jobs/mysql" -}}
          MYSQL_USER={{ .username }}
          MYSQL_PASSWORD={{ .password }}
          MYSQL_ROOT_PASSWORD={{ .password }}
          {{- end -}}
        EOH
      }

      resources {
        cpu    = 500
        memory = 128
      }

      service {
        name = "phpmyadmin"
        port = "phpmyadmin"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.phpmyadmin.rule=Host(`mysql.elates.it`)",
          "traefik.http.routers.phpmyadmin.tls.certresolver=letsencrypt",
        ]
      }
    }
  }
}

