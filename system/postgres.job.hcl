job "postgres" {
  region      = "global"
  type        = "service"
  priority    = 80

  group "postgres" {
    constraint {
      attribute = "${node.class}"
      value     = "storage"
    }

    restart {
      attempts = 5
      interval = "30m"
      delay    = "20s"
      mode     = "delay"
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
      driver = "docker"
      user   = "1000"

      config {
        image = "postgres:15-alpine"
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
        cpu    = 1000
        memory = 512
      }
      service {
        name = "postgres"
        port = "postgres"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "60s"
          timeout  = "3s"
        }
      }
    }
  }

  group "pgweb" {
    constraint {
      attribute = "${node.class}"
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
        image = "sosedoff/pgweb"
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

