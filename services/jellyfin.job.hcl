job "jellyfin" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  group "jellyfin" {
    network {
      port "http" {
        to = 8096
      }
      port "dlna" {
        static = 1900
      }
      port "autodiscovery" {
        static = 7359
      }
    }

    volume "jellyfin" {
      type            = "csi"
      source          = "jellyfin"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    volume "multimedia" {
      type      = "host"
      source    = "multimedia"
      read_only = true
    }

    service {
      name = "jellyfin"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.jellyfin.rule=Host(`media.elates.it`)",
        "traefik.http.routers.jellyfin.tls.certresolver=letsencrypt",
      ]

    }

    task "jellyfin" {
      driver = "docker"

      config {
        image = "jellyfin/jellyfin"
        ports = ["http", "dlna", "autodiscovery"]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
          JELLYFIN_DATA_DIR = "/data"
          JELLYFIN_PublishedServerUrl = "media.elates.it"
        EOF
      }


      volume_mount {
        volume      = "multimedia"
        destination = "/media"
        read_only   = true
      }

      volume_mount {
        volume      = "jellyfin"
        destination = "/data"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}


