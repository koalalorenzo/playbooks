job "traefik" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "system"
  priority    = 90


  group "traefik" {
    # If there the Nomad server is disconected for more than 1 min, and 
    # allocation does not have a heartbeat for 1 min, then kill it
    max_client_disconnect = "1m"

    update {
      max_parallel     = 1
      health_check     = "checks"
      min_healthy_time = "60s"
      healthy_deadline = "5m"
    }

    restart {
      # Restart every 30 seconds for 3 times, and then wait 1 min to try again
      delay    = "15s"
      interval = "1m"
      attempts = 4
      mode     = "delay" # try again, never fail
    }

    network {
      port "dns" {
        static = 53
      }

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
      name     = "traefik"
      provider = "nomad"

      port = "api"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "60s"
        timeout  = "10s"
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.http.rule=Host(`traefik.elates.it`)",
        "traefik.http.routers.traefik.tls.certresolver=letsencrypt",
      ]
    }


    volume "config" {
      type   = "host"
      source = "traefik"
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v2.10"
        network_mode = "host"

        ports = ["http", "https", "api"]

        volumes = [
          "local/traefik.yaml:/etc/traefik/traefik.yaml",
          "local/services.yaml:/etc/traefik/services.yaml",
        ]
      }

      volume_mount {
        volume      = "config"
        destination = "/etc/traefik/"
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
          {{- with nomadVar "nomad/jobs/traefik" -}}
            CF_DNS_API_TOKEN = "{{ .CF_DNS_API_TOKEN }}"
            CF_API_EMAIL = "{{ .CF_API_EMAIL }}"
          {{- end -}}
        EOF
      }

      template {
        data = <<EOF
entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entrypoint:
          to: websecure
          scheme: https

  websecure:
    address: ":443"
    http:
      tls:
        certResolver: "letsencrypt"
        domains:
           - main: elates.it
           - main: home.elates.it
             sans: "*.home.elates.it"

  dns-udp:
    address: ":53/udp"
  
  traefik:
    address: ":8081"

certificatesResolvers:
  letsencrypt:
    acme:
      storage: /etc/traefik/acme.json
      # Production Let's encrypt
      caServer: "https://acme-v02.api.letsencrypt.org/directory"
      # Sets the certificate to last 15 days
      certificatesDuration: 360
      dnsChallenge:
        provider: "cloudflare"
        resolvers: 
          - "1.1.1.1:53"
          - "1.0.0.1:53"
        delayBeforeCheck: 30

metrics:
  prometheus: {}

api:
  dashboard: true
  insecure: true
  debug: true

# Enable Consul Catalog configuration backend.
providers:
  file:
    filename: /etc/traefik/services.yaml

  nomad:
    endpoint:
      address: http://127.0.0.1:4646
    defaultRule: "Host(`{{"{{"}} .Name {{"}}"}}.elates.it`)"

  # Load config from Consul. Disable because unstalbe
  # consul:
  #   endpoints: 
  #     - "127.0.0.1:8500"
  #   rootKey: "traefik"

  # Load catalog from Consul
  consulCatalog:
    prefix: "traefik"
    exposedByDefault: false
    defaultRule: "Host(`{{"{{"}} .Name {{"}}"}}.elates.it`)"

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
        cpu    = 200
        memory = 128
      }
    }
  }
}

