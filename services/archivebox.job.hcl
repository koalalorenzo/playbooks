job "archivebox" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  update {
    min_healthy_time = "30s"
  }

  constraint {
    attribute = "${node.class}"
    value     = "compute"
  }

  group "archivebox" {
    network {
      port "http" {}

      port "archivebox"{
        to = 8000
      }
    }

    volume "archivebox" {
      type            = "csi"
      source          = "archivebox"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "cache" {
      driver = "docker"
      config {
        image = "nginx:alpine"

        volumes = ["local/default:/etc/nginx/conf.d/default.conf"]
        ports = ["http"]
      }

      template {
        destination = "local/default"
        change_mode = "restart"
        data        = <<EOF
          proxy_cache_path /tmp/archivebox levels=1:2 keys_zone=archivebox:5m max_size=128m inactive=60m use_temp_path=off;
        
          server {
            listen {{ env "NOMAD_PORT_http" }};
            # To disable buffering
            proxy_buffering off;

            location / {
              proxy_read_timeout 300s;
              proxy_connect_timeout 120s;
              proxy_cache archivebox;
              proxy_pass http://{{ env "NOMAD_ADDR_archivebox" }};
            }
          }

        EOF
      }

      
      service {
        name = "archivebox-cache"
        port = "http"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.archivebox.rule=Host(`archive.elates.it`)",
          "traefik.http.routers.archivebox.tls.certresolver=letsencrypt",
        ]
      }

      resources {
        memory = 128
      }
    }

    task "archivebox" {
      driver = "docker"

      config {
        image              = "archivebox/archivebox:latest"
        image_pull_timeout = "10m"

        ports = ["archivebox"]
      }

      
    service {
      name = "archivebox"
      port = "archivebox"
    }


      volume_mount {
        volume      = "archivebox"
        destination = "/data"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
