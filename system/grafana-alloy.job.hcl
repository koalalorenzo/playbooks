job "grafana" {
  type     = "system"
  priority = 90

  group "alloy" {
    update {
      max_parallel     = 1
      health_check     = "checks"
      min_healthy_time = "60s"
      healthy_deadline = "5m"
    }

    restart {
      delay    = "5s"
      interval = "5m"
      attempts = 55
      mode     = "delay"
    }

    network {
      port "http" {
        static = 27373
      }
    }

    service {
      name = "alloy"
      port = "http"

      # check {
      #   name     = "alive"
      #   type     = "tcp"
      #   port     = "http"
      #   interval = "30s"
      #   timeout  = "15s"
      # }

      tags = [
        "traefik.enable=false",
      ]
    }

    task "alloy" {
      driver       = "docker"
      kill_timeout = "30s"

      config {
        image        = "grafana/alloy:latest"
        args         = [
          "run",
          "--server.http.listen-addr=0.0.0.0:${NOMAD_PORT_http}",
          "--server.http.enable-pprof=false",
          "--cluster.enabled=true",
          "--cluster.join-addresses=192.168.197.3:${NOMAD_PORT_http},192.168.197.4:${NOMAD_PORT_http},192.168.197.5:${NOMAD_PORT_http},",
          "--cluster.advertise-address=${NOMAD_ADDR_http}",
          "--storage.path=/var/lib/alloy/data",
          "/etc/alloy/config.alloy"
        ]

        ports = ["http"]

        volumes = [
          "local/config.alloy:/etc/alloy/config.alloy",
        ]
      }


      template {
        destination = "local/config.alloy"
        data = <<EOF
          logging {
            level  = "info"
            format = "logfmt"
          }

          discovery.consul "consul" {
            server = "localhost:8500"
          }

          discovery.docker "containers" {
            host = "unix:///var/run/docker.sock"
          }
        EOF
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}

