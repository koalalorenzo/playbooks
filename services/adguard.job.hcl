job "adguard" {
  type        = "service"

  group "home" {
    network {
      port "http" {
        to = 3000
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
        "traefik.tcp.routers.adguard-dns-tls.entrypoints=dns-tls",
        "traefik.http.routers.adguard.rule=Host(`dns.elates.it`)",
        "traefik.http.routers.adguard.tls.certresolver=letsencrypt",
      ]
    }
    
    service {
      name = "adguard-dns-tls"
      port = "dns-tls"

      tags = [
        "traefik.enable=true",
        "traefik.tcp.routers.adguard-dns-tls.entrypoints=dns-quic,dns-tls",
        "traefik.tcp.routers.adguard-dns-tls.rule=HostSNI(`dns.elates.it`)",
        "traefik.tcp.routers.adguard-dns-tls.tls.certresolver=letsencrypt",
      ]
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



