job "restic-server" {
  type     = "service"
  priority = 60

  affinity {
    attribute = node.class
    value     = "compute"
    weight    = 80
  }

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

      check {
        name     = "alive"
        type     = "tcp"
        interval = "300s"
        timeout  = "30s"
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.resticserver.rule=Host(`restic.elates.it`)",
        "traefik.http.routers.resticserver.tls.certresolver=letsencrypt",
      ]

    }

    task "restic-server" {
      driver       = "docker"
      user         = "1000"
      kill_timeout = "60s"


      config {
        image = "restic/rest-server"
        ports = ["http"]
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
          OPTIONS="--prometheus --debug --no-auth --listen=:{{ env "NOMAD_PORT_http" }}"
        EOF
      }

      volume_mount {
        volume      = "restic"
        destination = "/data"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }
}


