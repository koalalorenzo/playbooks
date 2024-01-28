job "redis" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"
  priority    = 80

  group "redis" {
    restart {
      attempts = 5
      interval = "5m"
      delay    = "30s"
      mode     = "delay"
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
      driver = "docker"
      user   = "1000"

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
# save 3600 1 300 100 60 10000
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
        memory = 512
      }

      service {
        name = "redis"
        port = "redis"

        check {
          name     = "alive"
          type     = "tcp"
          interval = "60s"
          timeout  = "3s"
        }
      }
    }
  }
}

