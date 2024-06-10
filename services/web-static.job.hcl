job "web-static" {
  type = "service"

  group "server" {
    count = 2
    
    network {
      port "http" {
        to = 80
      }
    }

    constraint {
      operator = "distinct_hosts"
      value    = "true"
    }

    service {
      name = "web-static"
      port = "http"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "120s"
        timeout  = "15s"

        check_restart {
          limit = 3
          grace = "30s"
        }
      }

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.static.rule=Host(`static.elates.it`) || Host(`static.ts.elates.it`)",
      ]
    }

    volume "web-static" {
      type            = "csi"
      source          = "web-static"
      attachment_mode = "file-system"
      access_mode     = "multi-node-reader-only"
      read_only       = true
    }

    task "nginx" {
      driver       = "docker"
      kill_timeout = "10s"

      config {
        image = "nginx:alpine"

        ports = ["http"]

        volumes = [
          "local/default:/etc/nginx/conf.d/default.conf",
        ]

        labels {
          persist_logs = "true"
        }
      }

      volume_mount {
        volume      = "web-static"
        destination = "/var/www/"
      }

      template {
        data = <<EOF
        server {
          listen       80;
          listen  [::]:80;
          server_name  localhost;
    
          location / {
            root   /var/www;
            index  index.html index.htm;

            autoindex on;

            # Better Cache
            
            expires 6h;
            add_header Cache-Control "must-revalidate, stale-if-error=86400";

            location ~* \.(js|jpg|gif|png|css|import|pck|wasm)$ {
               expires 31d;
            }

            location ~* \.(html|htm|xml|rss)$ {
               expires 1h;
            }
            
            # Disabled: No cache plz
            # add_header Cache-Control 'private no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0';
            
            # Allow Godot Games
            add_header Cross-Origin-Opener-Policy 'same-origin';
            add_header Cross-Origin-Embedder-Policy 'require-corp';
          }

          error_page   500 502 503 504  /50x.html;
          location = /50x.html {
              expires 30s;
              root   /usr/share/nginx/html;
          }
        }
        EOF

        destination = "local/default"
      }

      resources {
        cpu    = 128
        memory = 64
      }

      affinity {
        attribute = node.class
        value     = "compute"
        weight    = 90
      }
    }
  }
}

