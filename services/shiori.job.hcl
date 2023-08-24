job "shiori" {
  type = "service"

  constraint {
    attribute = "${node.class}"
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
        image = "ghcr.io/go-shiori/shiori"
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
          SHIORI_DBMS=postgresql
          {{ with nomadVar "nomad/jobs/shiori" }}
          SHIORI_PG_USER={{ .SHIORI_PG_USER }}
          SHIORI_PG_PASS={{ .SHIORI_PG_PASS }}
          SHIORI_PG_NAME={{ .SHIORI_PG_NAME }}
          {{ end }}

          {{ range service "postgres" }}
          SHIORI_PG_HOST={{ .Address }}
          SHIORI_PG_PORT={{ .Port }}
          {{ end }}
          SHIORI_PG_SSLMODE=disable
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
        memory = 1024
      }
    }
  }
}
