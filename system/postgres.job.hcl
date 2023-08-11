job "postgres" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"
  priority = 80

  # Prefer but not enforce to run on compute1
  affinity {
    attribute = "${attr.unique.hostname}"
    value     = "compute1"
    weight    = 100
  }
  
  group "postgres" {
    restart {
      attempts = 5
      interval = "30m"
      delay    = "20s"
      mode     = "fail"
    }
    
    volume "postgres" {
      type      = "csi"
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
      source    = "postgres"    
    }

    network {
      port "postgres" { to = 5432 }
    }
    
    task "postgres" {
      driver = "docker"
      user = "1000"
      config {
        image = "postgres:15-alpine"
        ports = ["postgres"]
      }
      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          {{- with nomadVar "nomad/jobs/postgres" -}}
          POSTGRES_USER={{ .username }}
          POSTGRES_PASSWORD={{ .password }}
          {{- end -}}
        EOH
      }
      volume_mount {
        volume      = "postgres"
        destination = "/var/lib/postgresql/data"
        read_only   = false
      }
      resources {
        cpu    = 120
        memory = 250
      }
      service {
        name     = "postgres"
        port     = "postgres"
        
        check {
          name     = "alive"
          type     = "tcp"
          interval = "60s"
          timeout  = "3s"
        }
      }
    }
  }
  
  group "pgweb" {
    network {
      port "pgweb" {}
    }

    task "pgweb" {
      driver = "exec"

      config {
        command = "/bin/bash"
        args    = ["local/start.sh"]
      }
  

      template {
        destination   = "local/start.sh"
        change_mode   = "signal"
        change_signal = "SIGINT"
        perms         = "0755"

        data = <<EOF
          #!/bin/bash
          curl -s -L https://api.github.com/repos/sosedoff/pgweb/releases/latest \
            | grep {{ env "attr.kernel.name"}}_{{ env "attr.cpu.arch" }}.zip \
            | grep download \
            | cut -d '"' -f 4 \
            | wget -qi - \
            && unzip pgweb_{{ env "attr.kernel.name"}}_{{ env "attr.cpu.arch" }}.zip \
            && rm pgweb_{{ env "attr.kernel.name"}}_{{ env "attr.cpu.arch" }}.zip \
            && mv pgweb_{{ env "attr.kernel.name"}}_{{ env "attr.cpu.arch" }} ./pgweb
          chmod +x ./pgweb
          
          {{ range service "postgres" }}
          export POSTGRES_HOST={{ .Address }}:{{ .Port }}
          {{ end }}
          
          {{ with nomadVar "nomad/jobs/postgres" }}
          POSTGRES_USER={{ .username }}
          POSTGRES_PASSWORD={{ .password }}
          
          ./pgweb \
            --listen={{ env "NOMAD_PORT_pgweb" }} --bind="0.0.0.0" --skip-open \
            --auth-user={{ .username }} --auth-pass="{{ .password }}" \
            --url="postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST/?sslmode=disable"
          {{ end }}
        EOF
      }

      resources {
        cpu    = 500
        memory = 64
      }
      
      service {
        name     = "pgweb"
        port     = "pgweb"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.http.rule=Host(`postgres.elates.it`)",
          "traefik.http.routers.http.tls.certresolver=letsencrypt",
        ]        
      }
    }
  }
}

