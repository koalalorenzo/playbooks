job "traefik" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "system"

  group "traefik" {
    network {
      port "http" {
        static = 80
      }
      
      port "https" {
        static = 443
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

    volume "certs" {
      type = "host"
      read_only = true
      source = "priv-certs"
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

      volume_mount {
        volume      = "certs"
        destination = "/etc/ssl/private/"
        propagation_mode = "private"
      }


      template {
        data = <<EOF
entryPoints:
  http:
    address: ":80"
  https:
    address: ":443"
  traefik:
    address: ":8081"

# certificatesResolvers:
#   dns-cloudflare:
#     acme:
#       caServer: "https://acme-staging-v02.api.letsencrypt.org/directory"
#       email: ""
#       certificatesDuration:
#       dnsChallenge:
#         provider: "cloudflare"
#         resolvers: "1.1.1.1:53,1.0.0.1:53"
#         delayBeforeCheck=90

metrics:
  prometheus: {}

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
      rule: "Host(`nomad.elates.it`)"
      service: "nomad-service"
      tls:
        certresolver: letsencrypt

    consul:
      rule: "Host(`consul.elates.it`)"
      service: "consul-service"
      tls:
        certresolver: letsencrypt

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

