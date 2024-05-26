job "shiori-update" {
  type = "batch"

  periodic {
    crons            = ["45 */4 * * *"]
    prohibit_overlap = true
    time_zone        = "CET"
  }

  affinity {
    attribute = meta.run_batch
    value     = "true"
    weight    = 90
  }

  group "shiori" {
    volume "shiori" {
      type            = "csi"
      source          = "shiori"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "shiori" {
      driver = "docker"

      config {
        image      = "ghcr.io/go-shiori/shiori:v1.6.3"
        entrypoint = ["/bin/sh"]
        command    = "${NOMAD_TASK_DIR}/update.sh"
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          SHIORI_DIR=/shiori
          {{ range service "postgres" }}
            SHIORI_DATABASE_URL=postgres://{{ with nomadVar "nomad/jobs/shiori" }}{{ .POSTGRES_USERNAME }}:{{ .POSTGRES_PASSWORD }}{{ end }}@{{ .Address }}:{{ .Port }}/shiori?sslmode=disable
          {{ end }}
          {{ with nomadVar "nomad/jobs/shiori" }}
          SHIORI_HTTP_SECRET_KEY="{{ .SHIORI_HTTP_SECRET_KEY }}"
          {{ end }}
        EOH
      }

      template {
        destination = "${NOMAD_TASK_DIR}/update.sh"
        change_mode = "restart"
        data        = <<EOH
          #!/usr/bin/env bash

          # Define RSS feed URL
          RSS_FEED_URL="https://getpocket.com/users/koalalorenzo/feed/all"
          # File to keep track of processed URLs
          PROCESSED_URLS_FILE="/shiori/processed_urls.txt"

          # Fetch RSS feed using curl
          wget -q -O - "$RSS_FEED_URL" > rss_feed.xml

          # Extract URLs from the RSS feed using grep and sed
          URLS=$(grep -o '<link>[^<]*' rss_feed.xml | sed -n 's/<link>//p')

          # Loop through each URL and run shiori add command
          for URL in $URLS; do
              # Check if URL is already processed
              if grep -q "$URL" "$PROCESSED_URLS_FILE"; then
                  echo "Skipping $URL, already processed."
              else
                  echo "Adding $URL to Shiori"
                  # Add URL to Shiori
                  shiori add "$URL"
                  # Add URL to processed list
                  echo "$URL" >> "$PROCESSED_URLS_FILE"
              fi
          done

          # Clean up the temporary RSS file
          rm rss_feed.xml
        EOH
      }

      volume_mount {
        volume      = "shiori"
        destination = "/shiori"
      }

      resources {
        cpu    = 250
        memory = 32
      }
    }
  }
}
