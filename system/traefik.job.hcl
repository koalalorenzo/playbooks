job "traefik" {
  type     = "system"
  priority = 90

  constraint {
    attribute = "${meta.traefik}"
    operator  = "is_set"
  }

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
      delay    = "5s"
      interval = "5m"
      attempts = 55
      mode     = "delay"
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

      port "terraria" {
        static = 7777
      }

    }

    service {
      name = "traefik"
      # Using Consul for livecheck and alerts with grafana
      # provider = "nomad" 
      port = "api"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "30s"
        timeout  = "15s"
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.http.rule=Host(`traefik.elates.it`) || Host(`traefik.ts.elates.it`)",
        "traefik.http.routers.traefik.tls.certresolver=letsencrypt",
      ]
    }


    volume "config" {
      type   = "host"
      source = "traefik"
    }

    task "traefik" {
      driver       = "docker"
      kill_timeout = "30s"

      config {
        image        = "traefik:v2.11.2"
        network_mode = "host"

        ports = ["http", "https", "api", "dns", "terraria"]

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
          permanent: false

  websecure:
    address: ":443"
    http:
      tls:
        certResolver: "letsencrypt"
        domains:
           - main: elates.it
             sans:
               - "*.ts.elates.it"
               - "*.elates.it"

  dns-udp:
    address: ":53/udp"
  
  traefik:
    address: ":8081"

  terraria-tcp:
    address: ":7777"
    
  terraria-udp:
    address: ":7777/udp"

  iperf-tcp:
    address: ":5201"

  iperf-udp:
    address: ":5201/udp"

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
          - "8.8.8.8:53"
          - "8.8.4.4:53"
        delayBeforeCheck: 60
        disablePropagationCheck: true

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
    defaultRule: "Host(`{{"{{"}} .Name {{"}}"}}.elates.it`) || Host(`{{"{{"}} .Name {{"}}"}}.ts.elates.it`)"

  # Load config from Consul. Disable because unstalbe
  # consul:
  #   endpoints: 
  #     - "127.0.0.1:8500"
  #   rootKey: "traefik"

  # Load catalog from Consul
  consulCatalog:
    prefix: "traefik"
    exposedByDefault: false
    defaultRule: "Host(`{{"{{"}} .Name {{"}}"}}.elates.it`) || Host(`{{"{{"}} .Name {{"}}"}}.ts.elates.it`)"

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
      rule: "Host(`nomad.elates.it`) || Host(`nomad.ts.elates.it`)"
      service: "nomad-service"
      tls:
        certresolver: letsencrypt

    consul:
      rule: "Host(`consul.elates.it`) || Host(`consul.ts.elates.it`)"
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
        cpu    = 500
        memory = 256
      }
    }
  }
}

