job "http-proxy" {
  type     = "service"
  priority = 70

  constraint {
    attribute = node.class
    value     = "compute"
  }

  group "squid" {
    network {
      port "http" {}
    }

    service {
      name = "http-proxy"
      port = "http"

      check {
        name = "alive"
        type = "tcp"
        port = "http"

        interval = "60s"
        timeout  = "15s"

        check_restart {
          limit = 3
          grace = "60s"
        }
      }

      tags = [
        "traefik.enable=true",
        "traefik.tcp.routers.http-proxy.rule=HostSNI(`*`)",
        "traefik.tcp.routers.http-proxy.entrypoints=http-proxy",
      ]
    }

    task "squid" {
      driver = "docker"

      config {
        image = "ubuntu/squid"
        ports = ["http"]

        volumes = [
          "local/squid.conf:/etc/squid/squid.conf",
        ]

        ulimit {
          nofile = "524288:524288"
        }
      }

      template {
        destination = "local/squid.conf"
        change_mode = "restart"
        data        = <<EOH
          http_port {{ env "NOMAD_PORT_http" }}
          http_access allow all
          http_access allow localhost
          # http_access deny all

          # Max 10 GB, 16 main directory and 256 sub directories 
          cache_dir ufs /var/spool/squid 10000 16 256
        EOH
      }

      volume_mount {
        volume      = "http-proxy"
        destination = "/var/spool/squid"
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }

    volume "http-proxy" {
      type            = "csi"
      source          = "http-proxy"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }
  }
}
