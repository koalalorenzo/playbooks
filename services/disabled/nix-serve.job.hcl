job "nix-serve" {
  type = "service"

  constraint {
    attribute = node.class
    value     = "storage"
  }

  group "cache" {
    restart {
      delay    = "5s"
      interval = "30s"
      attempts = 3
      mode     = "delay"
    }

    network {
      port "http" {}
    }

    service {
      name = "nix-serve"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.nixserve.rule=Host(`nix.elates.it`)",
        "traefik.http.routers.nixserve.tls.certresolver=letsencrypt",
      ]

      check {
        name = "nix-serve"
        type = "http"
        path = "/nix-cache-info"

        interval                 = "60s"
        timeout                  = "10s"
        success_before_passing   = 1
        failures_before_critical = 3
      }
    }

    task "serve" {
      driver = "raw_exec"

      config {
        command = "/bin/bash"
        args    = ["local/start.sh"]
      }

      template {
        destination   = "local/start.sh"
        change_mode   = "signal"
        change_signal = "SIGINT"
        perms         = "0755"

        data = <<EOF
          #!/usr/bin/env bash
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          set -ex

          nix --extra-experimental-features "nix-command flakes" \
            run nixpkgs\#nix-serve -- \
             --port {{ env `NOMAD_PORT_http` }} \
             --workers 2
        EOF
      }

      resources {
        cpu    = 1000
        memory = 512
      }
    }
  }
}



