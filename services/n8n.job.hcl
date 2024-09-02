job "n8n" {
  type     = "service"

  constraint {
    attribute = node.class
    value     = "compute"
  }

  group "n8n" {
    network {
      port "http" {}
    }

    service {
      name = "n8n"
      port = "http"

      check {
        name = "alive"
        type = "http"
        path = "/healthz"

        interval = "120s"
        timeout  = "10s"
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.n8n.rule=Host(`n8n.elates.it`)",
        # "traefik.http.middlewares.n8n.headers.SSLRedirect=true",
        # "traefik.http.middlewares.n8n.headers.STSSeconds=315360000",
        # "traefik.http.middlewares.n8n.headers.browserXSSFilter=true",
        # "traefik.http.middlewares.n8n.headers.contentTypeNosniff=true",
        # "traefik.http.middlewares.n8n.headers.forceSTSHeader=true",
        # "traefik.http.middlewares.n8n.headers.SSLHost=n8n.elates.it",
        # "traefik.http.middlewares.n8n.headers.STSIncludeSubdomains=true",
        # "traefik.http.middlewares.n8n.headers.STSPreload=true",
      ]
    }

    task "n8n" {
      driver       = "docker"
      kill_timeout = "45s"

      config {
        image = "ghcr.io/n8n-io/n8n:latest"
        ports = ["http"]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          DB_TYPE="postgresdb"
          DB_POSTGRESDB_DATABASE="n8n"
          {{ range service "postgres" }}
            DB_POSTGRESDB_HOST={{ .Address }}
            DB_POSTGRESDB_PORT={{ .Port }}
          {{ end }}
          
          {{- with nomadVar "nomad/jobs/n8n" }}
            DB_POSTGRESDB_USER={{ .POSTGRES_USERNAME }}
            DB_POSTGRESDB_PASSWORD={{ .POSTGRES_PASSWORD }}
            DB_POSTGRESDB_SCHEMA={{ .POSTGRES_USERNAME }}

            N8N_ENCRYPTION_KEY="{{ .N8N_ENCRYPTION_KEY }}"
          {{- end }}

          N8N_HIRING_BANNER_ENABLED="false"
          N8N_REINSTALL_MISSING_PACKAGES="true"
          
          N8N_METRICS="true"
          N8N_METRICS_INCLUDE_DEFAULT_METRICS="false"
          N8N_METRICS_INCLUDE_WORKFLOW_ID_LABEL="true"
          
          N8N_PROTOCOL="https"
          N8N_PORT={{ env "NOMAD_PORT_http" }}
          N8N_HOST="0.0.0.0"
          N8N_LISTEN_ADDRESS="0.0.0.0"

          WEBHOOK_URL="https://n8n.elates.it"
          N8N_SECURE_COOKIE=false

          EXECUTIONS_TIMEOUT="900" # Max 15 min of execution
          N8N_CONCURRENCY_PRODUCTION_LIMIT="2" # Max 2 exec at the same time

          GENERIC_TIMEZONE="Europe/Copenhagen"
          TZ="Europe/Copenhagen"
          NODE_ENV=production

          N8N_DIAGNOSTICS_ENABLED=true
        EOH
      }

      volume_mount {
        volume      = "data"
        destination = "/home/node/.n8n"
        read_only   = false
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }

    volume "data" {
      type            = "csi"
      source          = "n8n"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }
  }
}
