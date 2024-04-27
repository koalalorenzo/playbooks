job "7dtd" {
  type     = "service"

  group "7dtd" {
    constraint {
      attribute = node.class
      value     = "compute"
    }

    constraint {
      attribute = attr.cpu.arch
      value     = "amd64" #arm64 for arm64
    }

    network {
      port "game_server_z" { static = 26900 } # Default game ports tcp + udp
      port "game_server_o" { static = 26901 } # Default game ports tcp + udp
      port "game_server_t" { static = 26902 } # udp 
      port "webadmin" { to = 8080 } # OPTIONAL - WEBADMIN
      port "webserver" { to = 8082 } # OPTIONAL - WEBSERVER https://7dtd.illy.bz/wiki/Server%20fixes
    }

    restart {
      delay    = "10s"
      interval = "30s"
      attempts = 3
      mode     = "delay"
    }

    task "gameserver" {
      driver = "docker"
      kill_timeout = "120s"

      config {
        image = "vinanrra/7dtd-server"
        ports = [
          "game_server_z",
          "game_server_o",
          "game_server_t",
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
        cpu    = 3000
        memory = 10240
      }

      service {
        name = "webadmin"
        port = "webadmin"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.7dtd.rule=Host(`7dtd.elates.it`)",
          "traefik.http.routers.7dtd.tls.certresolver=letsencrypt",
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
}

