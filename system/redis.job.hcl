job "redis" {
  type     = "service"
  priority = 75

  group "redis" {
    affinity {
      attribute = node.class
      value     = "compute"
      weight    = 80
    }

    restart {
      attempts = 3
    }

    volume "data" {
      type            = "csi"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      source          = "redis"
    }

    network {
      port "redis" {}
    }

    task "redis" {
      driver       = "docker"
      user         = "999"
      kill_timeout = "60s"

      config {
        image = "redis:7.2-alpine"
        ports = ["redis"]
        args  = ["/usr/local/etc/redis/redis.conf"]
        volumes = [
          "local/redis.conf:/usr/local/etc/redis/redis.conf",
        ]

        sysctl = {
          #"vm.overcommit_memory" = "1"
        }
      }

      template {
        destination = "local/redis.conf"
        change_mode = "restart"
        data        = <<EOH
protected-mode no
port {{ env "NOMAD_PORT_redis" }}
loglevel warning
save 3600 1 300 100 60 10000
maxmemory 512m
EOH
      }

      volume_mount {
        volume      = "data"
        destination = "/data"
        read_only   = false
      }

      resources {
        cpu    = 1000
        memory = 256
      }

      service {
        name = "redis"
        port = "redis"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "60s"
          timeout  = "5s"

          check_restart {
            limit = 3
            grace = "30s"
          }
        }
      }
    }
  }
}

