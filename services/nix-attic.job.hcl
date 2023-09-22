job "nix-cache-attic" {
  type = "service"

  constraint {
    attribute = "${node.class}"
    value     = "compute"
  }

  group "cache" {
    restart {
      delay    = "5s"
      interval = "30s"
      attempts = 3
      mode     = "delay"
    }

    network {
      port "http" {
        to = 8080
      }
    }

    volume "data" {
      type            = "csi"
      source          = "nix-attic"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    service {
      name = "nix"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.nix.rule=Host(`nix.elates.it`)",
        "traefik.http.routers.nix.tls.certresolver=letsencrypt",
      ]

      check {
        name = "nix-serve-http"
        type = "http"
        path = "/nix-cache-info"

        interval                 = "300s"
        timeout                  = "10s"
        success_before_passing   = 1
        failures_before_critical = 3
      }
    }

    task "serve" {
      driver = "docker"

      config {
        image = "ghcr.io/zhaofengli/attic"
        ports = ["http"]
      }

      volume_mount {
        volume      = "data"
        destination = "/attic"
      }


      resources {
        cpu    = 1000
        memory = 512
      }
    }
  }
}



