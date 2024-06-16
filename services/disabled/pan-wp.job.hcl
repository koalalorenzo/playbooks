job "pan-wp" {
  type = "service"

  constraint {
    attribute = node.class
    value     = "compute"
  }

  group "pan-wp" {
    network {
      port "http" { to = 80 }
    }

    volume "pan-wp" {
      type            = "csi"
      source          = "pan-wp"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "pan-wp" {
      driver       = "docker"
      kill_timeout = "5s"

      config {
        image = "wordpress:6.5-php8.3-fpm-alpine"
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
            WORDPRESS_DB_HOST={{ .Address }}:{{ .Port }}
          {{ end }}
          {{ with nomadVar "nomad/jobs/pan-wp" }}
            WORDPRESS_DB_USER={{ .POSTGRES_USERNAME }}
            WORDPRESS_DB_PASSWORD={{ .POSTGRES_PASSWORD }}
            WORDPRESS_DB_NAME={{ .POSTGRES_USERNAME }}
          {{ end }}
          WORDPRESS_CONFIG_EXTRA=""
        EOH
      }

      service {
        name = "pan-wp"
        port = "http"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "600s"
          timeout  = "5s"
        }

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.pan-wp.rule=Host(`pan-wp.elates.it`) || Host(`1959e7525b23f0b0.elates.it`)",
          "traefik.http.routers.pan-wp.tls.certresolver=letsencrypt",
        ]

      }


      volume_mount {
        volume      = "pan-wp"
        destination = "/var/www/html"
      }

      resources {
        cpu    = 1000
        memory = 512
      }
    }
  }
}
