job "web-static" {
  type     = "service"

  group "server" {
    network {
      port "http" {}
    }

    service {
      name = "web-static"
      port = "api"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "120s"
        timeout  = "15s"
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.http.rule=Host(`*.elates.it`, `*.ts.elates.it`)",
      ]
    }


    task "nginx" {
      driver       = "docker"
      kill_timeout = "15s"

      config {
        image        = "nginx:alpine"

        ports = ["http"]

        volumes = [
          "local/default:/etc/nginx/sites/default",
        ]
      }

      volume_mount {
        volume      = "web-static"
        destination = "/var/www/"
      }

      template {
        data = <<EOF
        EOF

        destination = "local/default"
      }


      resources {
        cpu    = 500
        memory = 64
      }
    }
  }
}

