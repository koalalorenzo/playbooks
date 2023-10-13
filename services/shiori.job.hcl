job "shiori" {
  type = "service"

  constraint {
    attribute = node.class
    value     = "compute"
  }

  group "shiori" {
    network {
      port "http" { to = 8080 }
    }

    volume "shiori" {
      type            = "csi"
      source          = "shiori"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "shiori" {
      driver = "docker"

      config {
        image = "ghcr.io/go-shiori/shiori:v1.5.5"
        ports = ["http"]
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
          {{ range service "postgres" }}
            SHIORI_DATABASE_URL=postgres://{{ with nomadVar "nomad/jobs/shiori" }}{{ .POSTGRES_USERNAME }}:{{ .POSTGRES_PASSWORD }}{{ end }}@{{ .Address }}:{{ .Port }}/shiori?sslmode=disable
            SHIORI_DBMS=postgresql
            {{ with nomadVar "nomad/jobs/shiori" }}
            SHIORI_PG_USER="{{ .POSTGRES_USERNAME }}"
            SHIORI_PG_PASS="{{ .POSTGRES_PASSWORD }}"
            {{ end }}
            SHIORI_PG_NAME=shiori
            SHIORI_PG_HOST={{ .Address }}
            SHIORI_PG_PORT={{ .Port }}
            SHIORI_PG_SSLMODE=disable
          {{ end }}
        EOH
      }

      service {
        name = "shiori"
        port = "http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.shiori.rule=Host(`shiori.elates.it`)",
          "traefik.http.routers.shiori.tls.certresolver=letsencrypt",
        ]

      }


      volume_mount {
        volume      = "shiori"
        destination = "/shiori"
      }

      resources {
        cpu    = 1000
        memory = 512
      }
    }
  }
}
