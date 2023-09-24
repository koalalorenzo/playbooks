job "hishtory" {
  type = "service"

  constraint {
    attribute = "${node.class}"
    value     = "compute"
  }

  group "hishtory" {
    count = 1

    network {
      port "http" { to = 8080 }
    }

    task "hishtory" {
      driver = "docker"

      config {
        image = "lscr.io/linuxserver/hishtory-server:latest"
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
          PUID=1000
          PGID=1000
          TZ=Etc/UTC

          # Limit the users to just me
          # HISHTORY_MAX_NUM_USERS=1
          
          {{ range service "postgres" }}
            HISHTORY_POSTGRES_DB=postgresql://{{ with nomadVar "nomad/jobs/hishtory" }}{{ .POSTGRES_USERNAME }}:{{ .POSTGRES_PASSWORD }}{{ end }}@{{ .Address }}:{{ .Port }}/hishtory?sslmode=disable
          {{ end }}
        EOH
      }

      service {
        name = "hishtory"
        port = "http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.hishtory.rule=Host(`hishtory.elates.it`)",
          "traefik.http.routers.hishtory.tls.certresolver=letsencrypt",
        ]
      }


      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}

