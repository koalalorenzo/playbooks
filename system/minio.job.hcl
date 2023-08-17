job "minio" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"
  priority    = 80

  group "minio" {
    restart {
      attempts = 5
      interval = "30m"
      delay    = "20s"
      mode     = "fail"
    }

    volume "nfs" {
      type            = "host"
      source          = "nfs"
    }

    network {
      port "minioadm" { to = 9001 }
      port "minio" { to = 9000 }
    }

    task "minio" {
      driver = "docker"

      config {
        image = "quay.io/minio/minio"
        ports = ["minioadm", "minio"]
        args = [
          "server",
          "/data",
        ]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          {{- with nomadVar "nomad/jobs/minio" -}}
            MINIO_ROOT_USER={{ .username }}
            MINIO_ROOT_PASSWORD={{ .password }}
          {{- end -}}
          MINIO_SERVER_URL="https://minio.elates.it/"
        EOH
      }

      volume_mount {
        volume      = "nfs"
        destination = "/data"
        read_only   = false
      }
      resources {
        cpu    = 500
        memory = 512
      }
      
      service {
        name = "minio"
        port = "minio"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.minio.rule=Host(`minio.elates.it`)",
          "traefik.http.routers.minio.tls.certresolver=letsencrypt",
        ]
      }
    }
  }
}
