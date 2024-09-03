job "waha" {
  type     = "service"

  constraint {
    attribute = node.class
    value     = "compute"
  }

  group "waha" {
    network {
      port "http" {}
    }

    service {
      name = "waha"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.waha.rule=Host(`waha.elates.it`)",
      ]
    }

    task "waha" {
      driver       = "docker"
      kill_timeout = "30s"

      config {
        image = "devlikeapro/waha:noweb-arm"
        # image = "devlikeapro/waha:arm"
        ports = ["http"]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"

        data = <<EOH
          {{- with nomadVar "nomad/jobs/waha" }}
            WHATSAPP_API_KEY={{ .WHATSAPP_API_KEY }}
            WAHA_DASHBOARD_USERNAME={{ .WEB_USERNAME }}
            WAHA_DASHBOARD_PASSWORD={{ .WEB_PASSWORD }}
            WHATSAPP_SWAGGER_USERNAME={{ .WEB_USERNAME }}
            WHATSAPP_SWAGGER_PASSWORD={{ .WEB_PASSWORD }}
          {{- end }}
          WAHA_PRINT_QR=False
          WHATSAPP_FILES_LIFETIME=300

          WAHA_LOG_FORMAT=JSON
          WAHA_LOG_LEVEL=info
          WHATSAPP_DEFAULT_ENGINE=NOWEB
          # WHATSAPP_DEFAULT_ENGINE=WEBJS
          WAHA_PRINT_QR=False

          WHATSAPP_API_PORT={{ env "NOMAD_PORT_http" }}
          WHATSAPP_API_HOSTNAME={{ env "NOMAD_ADDR_http" }}

          GENERIC_TIMEZONE="Europe/Copenhagen"
          TZ="Europe/Copenhagen"
          NODE_ENV=production
        EOH
      }

      volume_mount {
        volume      = "data"
        destination = "/app/.sessions"
        read_only   = false
      }


      resources {
        cpu    = 500
        memory = 512
      }
    }

    volume "data" {
      type            = "csi"
      source          = "waha"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

  }
}
