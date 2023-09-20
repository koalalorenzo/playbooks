job "nix-serve" {
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

    volume "nix-store" {
      type            = "csi"
      source          = "nix-serve"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    service {
      name = "nix-serve-http"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.nixserve.rule=Host(`nix.elates.it`)",
        "traefik.http.routers.nixserve.tls.certresolver=letsencrypt",
      ]

      check {
        name = "nix-serve-http"
        type = "http"
        path = "/nix-cache-info"

        interval                 = "120s"
        timeout                  = "10s"
        success_before_passing   = 1
        failures_before_critical = 3
      }
    }

    task "resolver" {
      driver = "docker"

      config {
        image = "nixos/nix"
        command = "/run/current-system/sw/bin/nix"
        args    = ["run","github:edolstra/nix-serve"]
        ports = ["http"]
      }

      volume_mount {
        volume      = "nix-store"
        destination = "/nix"
      }

      template {
        destination   = "local/start.sh"
        change_mode   = "signal"
        change_signal = "SIGINT"
        perms         = "0755"

        data = <<EOF
          #!/usr/bin/env bash
          set -ex
          nix-env --install --attr nixpkgs.nix-serve
          nix-serve -p 8080
        EOF
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }
}



