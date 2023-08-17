job "restic-server" {
  type     = "service"
  priority = 60

  group "main" {
    network {
      port "http" {}
    }

    volume "restic" {
      type            = "csi"
      source          = "restic"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    service {
      name = "restic-server"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.resticserver.rule=Host(`restic.elates.it`)",
        "traefik.http.routers.resticserver.tls.certresolver=letsencrypt",
      ]

    }

    task "restic-server" {
      driver = "docker"
      user   = "1000"

      config {
        image = "restic/rest-server"
        ports = ["http"]
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
          OPTIONS="--prometheus --no-auth --listen=:{{ env "NOMAD_PORT_http" }}"
        EOF
      }

      volume_mount {
        volume      = "restic"
        destination = "/data"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}


