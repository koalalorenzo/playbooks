job "atuin" {
  type     = "service"
  priority = 70

  constraint {
    attribute = node.class
    value     = "compute"
  }

  group "atuin" {
    network {
      port "http" {}
    }

    service {
      name = "atuin"
      port = "http"

      # check {
      #   name = "alive"
      #   type = "http"
      #   path = "/"

      #   interval = "60s"
      #   timeout  = "10s"
      # }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.atuin.rule=Host(`atuin.elates.it`) || Host(`atuin.ts.elates.it`)",
      ]
    }

    task "atuin" {
      driver       = "docker"
      kill_timeout = "60s"

      config {
        image = "ghcr.io/atuinsh/atuin:v18.2.0"
        args  = ["server", "start"]
        ports = ["http"]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          RUST_LOG="info,atuin_server=debug"
          ATUIN_HOST="0.0.0.0"
          ATUIN_PORT={{ env "NOMAD_PORT_http" }}
          ATUIN_OPEN_REGISTRATION=true
          {{ range service "postgres" }}
            ATUIN_DB_URI="postgres://{{ with nomadVar "nomad/jobs/atuin" }}{{ .POSTGRES_USERNAME }}:{{ .POSTGRES_PASSWORD }}{{ end }}@{{ .Address }}:{{ .Port }}/atuin?sslmode=disable"
          {{ end }}
        EOH
      }

      resources {
        cpu    = 256
        memory = 64
      }
    }
  }
}
