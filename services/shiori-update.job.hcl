job "shiori-update" {
  type = "batch"

  periodic {
    cron             = "45 5 * * *"
    prohibit_overlap = true
    time_zone        = "CET"
  }

  constraint {
    attribute = "${node.class}"
    value     = "compute"
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
        image = "ghcr.io/go-shiori/shiori"
        entrypoint = ["/bin/sh"]
        command = "${NOMAD_TASK_DIR}/update.sh"
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          SHIORI_DBMS=postgresql
          {{ with nomadVar "nomad/jobs/shiori" }}
          SHIORI_PG_USER={{ .SHIORI_PG_USER }}
          SHIORI_PG_PASS={{ .SHIORI_PG_PASS }}
          SHIORI_PG_NAME={{ .SHIORI_PG_NAME }}
          {{ end }}

          {{ range service "postgres" }}
          SHIORI_PG_HOST={{ .Address }}
          SHIORI_PG_PORT={{ .Port }}
          {{ end }}
          SHIORI_PG_SSLMODE=disable
        EOH
      }

      template {
        destination = "${NOMAD_TASK_DIR}/update.sh"
        change_mode = "restart"
        data        = <<EOH
          # Define RSS feed URL
          RSS_FEED_URL="https://getpocket.com/users/koalalorenzo/feed/all"

          # Fetch RSS feed using curl
          wget -q -O - "$RSS_FEED_URL" > rss_feed.xml

          # Extract URLs from the RSS feed using grep and sed
          URLS=$(grep -o '<link>[^<]*' rss_feed.xml | sed -n 's/<link>//p')

          # Loop through each URL and run shiori add command
          for URL in $URLS; do
              echo "Adding $URL to Shiori"
              shiori add "$URL" -a
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
        cpu    = 1000
        memory = 1024
      }
    }
  }
}