job "terraria" {
  type = "service"

  group "game-server" {
    count = 1

    network {
      port "game" {}
      port "http" {}
    }

    service {
      name = "terraria"
      port = "game"

      tags = [
        "traefik.enable=true",
        "traefik.udp.routers.terraria.entrypoints=terraria-udp",
        "traefik.tcp.routers.terraria.rule=HostSNI(`*`)",
        "traefik.tcp.routers.terraria.entrypoints=terraria-tcp",
      ]
    }

    service {
      name = "terraria-api"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.terraria-api.entrypoints=web,websecure",
        "traefik.http.routers.terraria-api.rule=Host(`terraria.elates.it`)",
        "traefik.http.routers.terraria-api.tls.certresolver=letsencrypt",
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

      artifact {
        # This is a tar.zip file (?) and to ensure cache, we are downloading it as a file and not have nomad decompress
        # it for us.
        source      = "https://github.com/Pryaxis/TShock/releases/download/v5.2.0/TShock-5.2-for-Terraria-1.4.4.9-${attr.kernel.name}-${attr.cpu.arch}-Release.zip"

        options {
          archive = false
        }
      }

      template {
        destination   = "local/start.sh"
        change_mode   = "signal"
        change_signal = "SIGINT"
        perms         = "0755"

        data = <<EOF
          #!/bin/bash
          cd /server
          unzip -o -u /local/TShock-5.2-for-Terraria-1.4.4.9-{{ env "attr.kernel.name" }}-{{ env "attr.cpu.arch" }}-Release.zip -d /server
          tar -xf ./*.tar
          rm ./*.tar

          # Replace ports
          sed -i 's/"ServerPort": [0-9]\+/"ServerPort": {{ env "NOMAD_PORT_game" }}/' /server/tshock/config.json
          sed -i 's/"RestApiPort": [0-9]\+/"RestApiPort": {{ env "NOMAD_PORT_http" }}/' /server/tshock/config.json

          export DOTNET_BUNDLE_EXTRACT_BASE_DIR=/tmp/dotnetbundle/
          mkdir -p $DOTNET_BUNDLE_EXTRACT_BASE_DIR
          
          ./TShock.Installer \
            -ip 0.0.0.0 -p {{ env "NOMAD_PORT_game" }}  -maxplayers 4 \
            -config /server/tshock/config.json \
            -configpath /server/tshock/ \
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



