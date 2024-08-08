job "diun" {
  type = "batch"
  priority = 30

  periodic {
    crons            = ["@daily"]
    time_zone        = "CET"
    prohibit_overlap = true
  }

  affinity {
    attribute = meta.run_batch
    value     = "true"
    weight    = 90
  }

  group "diun" {
    task "diun" {
      driver = "docker"

      config {
        image = "ghcr.io/crazy-max/diun:4"

        labels {
          persist_logs = "true"
        }
      }

      volume_mount {
        volume      = "data"
        destination = "/data"
      }

      env = {
        "CONFIG" = "local/diun.yaml"
      }

      template {
        destination = "local/diun.yaml"
        data = <<EOF
          notif:
            mail:
              {{ with nomadVar "nomad/jobs/diun" }}
              host: "{{ .smtp_hostname }}"
              port: 465
              username: "{{ .smtp_username }}"
              password: "{{ .smtp_password }}"
              ssl: true
              from: "{{ .smtp_username }}"
              to:
                - "{{ .email_recepient }}"
              {{ end }}
              templateTitle: "{{ "{{ .Entry.Image }}" }} released"
              templateBody: |
                Docker tag {{ "{{ .Entry.Image }}" }} which you subscribed to through {{ " {{ .Entry.Provider }} " }} provider has been released.

          providers:
            nomad:
              address: "https://nomad.elates.it"
              watchByDefault: true
         EOF
      }

    }

    volume "data" {
      type            = "csi"
      source          = "diun"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

  }
}
