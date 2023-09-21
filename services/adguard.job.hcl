job "adguard" {
  type = "service"

  constraint {
    attribute = "${node.class}"
    value     = "compute"
  }

  group "home" {
    restart {
      delay    = "5s"
      interval = "30s"
      attempts = 3
      mode     = "delay"
    }

    network {
      port "http" {
        # Note that after the initial config, 
        # we need to set the port to 3000
        to = 3000
      }

      port "dns" {
        to = 53
      }
    }

    volume "work" {
      type            = "csi"
      source          = "adguard-work"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    volume "config" {
      type            = "csi"
      source          = "adguard-config"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
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
        ports = ["http", "dns"]
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
        cpu    = 2000
        memory = 2048
      }
    }
  }

  # Manual updates 
  update {
    max_parallel     = 1
    canary           = 1
    min_healthy_time = "30s"
    healthy_deadline = "1m"
    auto_revert      = true
    auto_promote     = true
  }

  # Migrations during node draining
  migrate {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "30s"
    healthy_deadline = "1m"
  }
}



