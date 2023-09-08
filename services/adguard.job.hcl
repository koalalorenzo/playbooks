job "adguard" {
  type        = "service"

  group "home" {
    network {
      port "http" {
        to = 80
      }
      
      port "dns" {
        to = 53
      }
      
      port "dns-tls" {
        to = 853
      }
    }

    volume "adguard" {
      type            = "csi"
      source          = "adguard"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }
    
    service {
      name = "adguard-http"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.adguard.rule=Host(`dns.elates.it`)",
        "traefik.http.routers.adguard.tls.certresolver=letsencrypt",
      ]
    }

    task "resolver" {
      driver = "docker"

      config {
        image = "adguard/adguardhome"
        ports = ["http", "dns", "dns-tls"]
      }
      
      volume_mount {
        volume      = "adguard"
        destination = "/config"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }
  }
}



