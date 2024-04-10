job "terraria" {
  type = "service"

  group "game-server" {
    count = 1

    network {
      port "game" {}
      port "http" {
        static = 7878
      }
    }

    service {
      name = "terraria"
      port = "game"

      tags = [
        "traefik.enable=true",
        "traefik.udp.routers.terraria-tcp.entrypoints=terraria-udp",
        "traefik.tcp.routers.terraria-tcp.rule=HostSNI(`*`)",
        "traefik.tcp.routers.terraria-tcp.entrypoints=terraria-tcp",
      ]
    }

    service {
      name = "terraria-http"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.terraria-http.entrypoints=web,websecure",
        "traefik.http.routers.terraria-http.rule=Host(`terraria.elates.it`)",
        "traefik.http.routers.terraria-http.tls.certresolver=letsencrypt",
      ]
    }

    volume "data" {
      type            = "csi"
      source          = "terraria"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "tshock" {
      driver       = "exec"
      kill_timeout = "60s"

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
          #!/bin/bash
          curl -L \
            --output tshock.zip \
            https://github.com/Pryaxis/TShock/releases/download/v5.2.0/TShock-5.2-for-Terraria-1.4.4.9-{{ env "attr.kernel.name" }}-{{ env "attr.cpu.arch" }}-Release.zip

          curl -L https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
          
          mkdir -p /server/dotnet
          bash ./dotnet-install.sh \
            --install-dir /server/dotnet --runtime dotnet --channel 6.0

          unzip -o -u tshock.zip -d /server
          cd /server
          tar -xf ./*.tar
          rm ./*.tar

          export DOTNET_ROOT=/server/dotnet
          export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
          export DOTNET_BUNDLE_EXTRACT_BASE_DIR=/tmp/dotnetbundle/
          mkdir -p $DOTNET_BUNDLE_EXTRACT_BASE_DIR
          
          ./TShock.Server \
            -ip 0.0.0.0 -p {{ env "NOMAD_PORT_game" }} -maxplayers 3 \
            -world /server/tshock/share/Worlds/banana.wld
        EOF
      }

      volume_mount {
        volume      = "data"
        destination = "/server/tshock"
      }

      resources {
        cpu    = 2500
        memory = 2048
      }
    }

    affinity {
      attribute = node.class
      value     = "compute"
      weight    = 90
    }
  }
}



