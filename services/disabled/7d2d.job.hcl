job "7d2d" {
  type = "service"

  group "7d2d" {
    constraint {
      attribute = node.class
      value     = "compute"
    }

    constraint {
      attribute = attr.cpu.arch
      value     = "amd64" # 7d2d supports only amd64
    }

    network {
      port "gsz" { static = 26900 } # Default game ports tcp + udp (game server zero)
      port "gso" { static = 26901 } # Default game ports tcp + udp (game server one)
      port "gst" { static = 26902 } # udp  (game server two)
      port "webadmin" { to = 8080 }           # OPTIONAL - WEBADMIN
      port "webserver" { to = 8082 }          # OPTIONAL - WEBSERVER https://7dtd.illy.bz/wiki/Server%20fixes
    }

    service {
      name = "sdtd-gsz"
      port = "gsz"

      tags = [
        "traefik-7d2d.enabled=true",
        "traefik.udp.routers.terraria.entrypoints=gsz-udp",
        "traefik.tcp.routers.terraria.entrypoints=gsz-tcp",
      ]
    }

    service {
      name = "sdtd-gso"
      port = "gso"

      tags = [
        "traefik-7d2d.enabled=true",
        "traefik.udp.routers.terraria.entrypoints=gso-udp",
        "traefik.tcp.routers.terraria.entrypoints=gso-tcp",
      ]
    }

    service {
      name = "sdtd-gst"
      port = "gst"

      tags = [
        "traefik-7d2d.enabled=true",
        "traefik.udp.routers.terraria.entrypoints=gst-udp",
        "traefik.tcp.routers.terraria.entrypoints=gst-tcp",
      ]
    }


    restart {
      delay    = "10s"
      interval = "30s"
      attempts = 3
      mode     = "delay"
    }

    task "gameserver" {
      driver       = "docker"
      kill_timeout = "120s"

      config {
        image = "vinanrra/7dtd-server"
        network_mode = "host"

        ports = [
          "gsz",
          "gso",
          "gst",
          "webadmin",
          "webserver",
        ]
      }

      volume_mount {
        volume      = "serverfiles"
        destination = "/home/sdtdserver/serverfiles"
      }

      volume_mount {
        volume      = "gamefiles"
        destination = "/home/sdtdserver/.local/share/7DaysToDie"
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          START_MODE=1 #Change between START MODES
          VERSION=stable # Change between 7 days to die versions
          PUID=1000 # Remember to use same as your user
          PGID=1000 # Remember to use same as your user
          
          TimeZone=Europe/Copenhagen # Optional - Change Timezone
          
          TEST_ALERT=NO # Optional - Send a test alert
          UPDATE_MODS=NO # Optional - This will allow mods to be update on start, each mod also need to have XXXX_UPDATE=YES to update on start
          MODS_URLS="" # Optional - Mods urls to install, must be ZIP or RAR.
          
          ALLOC_FIXES=NO # Optional - Install ALLOC FIXES
          ALLOC_FIXES_UPDATE=NO # Optional - Update Allocs Fixes before server start
          
          UNDEAD_LEGACY=NO # Optional - Install Undead Legacy mod, if DARKNESS_FALLS it's enable will not install anything
          UNDEAD_LEGACY_VERSION=stable # Optional - Undead Legacy version
          UNDEAD_LEGACY_UPDATE=NO # Optional - Update Undead Legacy mod before server start
          
          DARKNESS_FALLS=NO # Optional - Install Darkness Falls mod, if UNDEAD_LEGACY it's enable will not install anything
          DARKNESS_FALLS_UPDATE=NO  # Optional - Update Darkness Falls mod before server start
          DARKNESS_FALLS_URL=False # Optional - Install the provided Darkness Falls url
          
          CPM=NO # Optional - CSMM Patron's Mod (CPM)
          CPM_UPDATE=NO # Optional - Update CPM before server start
          
          BEPINEX=NO # Optional - BepInEx
          BEPINEX_UPDATE=NO # Optional - Update BepInEx before server start
          
          BACKUP=NO # Optional - Backup server at 5 AM
          MONITOR=NO # Optional - Keeps server up if crash
        EOH
      }

      resources {
        cpu    = 8000  # 8 Ghz (3Ghz per core)
        memory = 12288 # 14.5 GB of RAM
      }

      service {
        name = "7d2d"
        port = "webadmin"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.7d2d.rule=Host(`7d2d.elates.it`)",
          "traefik.http.routers.7d2d.tls.certresolver=letsencrypt",
        ]
      }
    }

    volume "serverfiles" {
      type            = "csi"
      source          = "7d2d-serverfiles"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "gamefiles" {
      type            = "csi"
      source          = "7d2d-gamefiles"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }
  }

  # group "traefik-7d2d" {
  #   constraint {
  #     attribute = meta.sdtd.port-forward
  #     operator  = "is_set"
  #   }

  #   network {
  #     port "gsz" { static = 26900 } # Default game ports tcp + udp
  #     port "gso" { static = 26901 } # Default game ports tcp + udp
  #     port "gst" { static = 26902 } # udp 
  #     port "webadmin" { to = 8080 }           # OPTIONAL - WEBADMIN
  #     port "webserver" { to = 8082 }          # OPTIONAL - WEBSERVER https://7dtd.illy.bz/wiki/Server%20fixes
  #   }

  #   task "traefik" {
  #     driver       = "docker"
  #     kill_timeout = "45s"

  #     config {
  #       image        = "traefik:v2.11.2"
  #       network_mode = "host"

  #       ports = [
  #         "gsz",
  #         "gso",
  #         "gst",
  #         "webadmin",
  #         "webserver",
  #       ]

  #       volumes = [
  #         "local/traefik.yaml:/etc/traefik/traefik.yaml",
  #       ]
  #     }

  #     template {
  #       data = <<EOF
  #         entryPoints:
  #           gsz-udp:
  #             address: ":26900/udp"
  #           gso-udp:
  #             address: ":26901/udp"
  #           gst-udp:
  #             address: ":26902/udp"

  #           gsz-tcp:
  #             address: ":26900"
  #           gso-tcp:
  #             address: ":26901"
  #           gst-tcp:
  #             address: ":26902"


  #         providers:
  #           consulCatalog:
  #             prefix: "traefik-7d2d"

  #             endpoint:
  #               address: "127.0.0.1:8500"
  #               scheme: "http"
  #         EOF

  #       destination = "local/traefik.yaml"
  #     }

  #     resources {
  #       cpu    = 250
  #       memory = 32
  #     }
  #   }
  # }
}

