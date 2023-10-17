locals {
  devices = [
    "/dev/video10",
    "/dev/video11",
    "/dev/video12",
    "/dev/video13",
    "/dev/video14",
    "/dev/video15",
    "/dev/video16",
    "/dev/video18",
    "/dev/video20",
    "/dev/video21",
    "/dev/video22",
    "/dev/video23",
    "/dev/video31",
  ]
}

job "jellyfin" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  group "jellyfin" {
    network {
      port "http" {
        to     = 8096
        static = 28480
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
      access_mode     = "single-node-writer"
    }

    volume "multimedia" {
      type            = "csi"
      source          = "multimedia"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
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
        image = "linuxserver/jellyfin"
        ports = ["http", "dlna", "autodiscovery"]

        devices = [for s in local.devices : {
          host_path      = s
          container_path = s
        }]
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
          PUID                        = "1000"
          PGID                        = "1000"
          JELLYFIN_PublishedServerUrl = "media.elates.it"
        EOF
      }


      volume_mount {
        volume      = "multimedia"
        destination = "/data"
      }

      volume_mount {
        volume      = "jellyfin"
        destination = "/config"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }
}


