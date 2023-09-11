job "adguard" {
  type        = "service"

  group "home" {
    restart {
      delay = "5s"
      interval = "30s"
      attempts = 3
      mode = "delay"
    }

    network {
      port "http" {
        # Note that after the initial config, we need to set the port to 3000
        to = 3000
      }
      
      port "dns" {
        to = 53
      }
      
      port "dns-tls" {
        to = 853
      }
    }

    volume "work" {
      type            = "csi"
      source          = "adguard-work"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    volume "config" {
      type            = "csi"
      source          = "adguard-config"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }
    
    service {
      name = "adguard-http"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.adguard.entrypoints=web,websecure",
        "traefik.http.routers.adguard.rule=Host(`dns.elates.it`)",
        "traefik.http.routers.adguard.tls.certresolver=letsencrypt",
      ]

      check {
        name     = "adguard-http"
        type     = "http"
        interval = "10s"
        timeout  = "2s"

        check_restart {
          limit = 3
          grace = "30s"
        }
      }
    }
    
    service {
      name = "adguard-dns"
      port = "dns"

      tags = [
        "traefik.enable=true",
        "traefik.udp.routers.adguard-dns.entrypoints=dns-udp",
      ]
    }

    task "resolver" {
      driver = "docker"

      config {
        image = "adguard/adguardhome"
        ports = ["http", "dns", "dns-tls"]
      }
      
      volume_mount {
        volume      = "work"
        destination = "/opt/adguardhome/work"
      }
      
      volume_mount {
        volume      = "config"
        destination = "/opt/adguardhome/conf"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }
}



