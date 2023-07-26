job "traefik" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "system"

  group "traefik" {
    network {
      port "http" {
        static = 80
      }

      port "api" {
        static = 8081
      }
    }

    service {
      name = "traefik"
      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "60s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.10"
        network_mode = "host"

        volumes = [
          "local/traefik.yaml:/etc/traefik/traefik.yaml",
          "local/services.yaml:/etc/traefik/services.yaml",
        ]
      }

      template {
        data = <<EOF
entryPoints:
  http:
    address: ":80"
  traefik:
    address: ":8081"

api:
  dashboard: true
  insecure: true

# Enable Consul Catalog configuration backend.
providers:
  file:
    filename: /etc/traefik/services.yaml
  nomad:
    endpoint:
      address: http://127.0.0.1:4646
    defaultRule: "Host(`{{ .Name }}.setale.me`)"
  consulCatalog:
    prefix: "traefik"
    exposedByDefault: false
    defaultRule: "Host(`{{ .Name }}.setale.me`)"

    endpoint:
      address: "127.0.0.1:8500"
      scheme: "http"
EOF

        destination = "local/traefik.yaml"
      }
      
      template {
        data = <<EOF
http:
  routers:
    nomad:
      rule: "Host(`nomad.setale.me`)"
      service: "nomad-service"

    consul:
      rule: "Host(`consul.setale.me`)"
      service: "consul-service"

  services:
    nomad-service:
      loadBalancer:
        servers:
        - url: "http://localhost:4646"

    consul-service:
      loadBalancer:
        servers:
        - url: "http://localhost:8500"
EOF

        destination = "local/services.yaml"
      }


      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}

