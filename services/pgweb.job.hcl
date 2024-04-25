job "pgweb" {
  type     = "service"

  group "pgweb" {
    constraint {
      attribute = node.class
      value     = "compute"
    }

    network {
      port "pgweb" { to = 8081 }
    }

    restart {
      delay    = "10s"
      interval = "30s"
      attempts = 3
      mode     = "delay"
    }

    task "pgweb" {
      driver = "docker"

      config {
        image = "sosedoff/pgweb:0.14.2"
        ports = ["pgweb"]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          {{- with nomadVar "nomad/jobs/postgres" -}}
          PGWEB_DATABASE_URL=postgresql://{{ .username }}:{{ .password }}@{{ range service "postgres" }}{{ .Address }}:{{ .Port }}{{ end }}/?sslmode=disable
          PGWEB_AUTH_USER={{ .username }}
          PGWEB_AUTH_PASS={{ .password }}
          {{- end -}}
        EOH
      }

      resources {
        cpu    = 500
        memory = 128
      }

      service {
        name = "pgweb"
        port = "pgweb"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.pgweb.rule=Host(`postgres.elates.it`)",
          "traefik.http.routers.pgweb.tls.certresolver=letsencrypt",
        ]
      }
    }
  }
}

