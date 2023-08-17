job "restic-cleanup-local" {
  type     = "batch"
  priority = 60

  periodic {
    cron             = "@daily"
    time_zone        = "CET"
    prohibit_overlap = true
  }

  group "restic" {
    task "restic" {
      driver = "exec"

      config {
        command = "/bin/bash"
        args    = ["local/backup.sh"]
      }

      template {
        destination   = "local/backup.sh"
        change_mode   = "signal"
        change_signal = "SIGINT"
        perms         = "0755"

        data = <<EOF
          #!/bin/bash -ex
          curl -L \
            --output restic.bz2 \
            https://github.com/restic/restic/releases/download/v0.16.0/restic_0.16.0_{{ env "attr.kernel.name" }}_{{ env "attr.cpu.arch" }}.bz2
          bunzip2 ./restic.bz2
          chmod +x ./restic

          ./restic self-update
          sleep 3

          export RESTIC_REPOSITORY="rest:https://restic.elates.it"
        
          {{ with nomadVar "nomad/jobs/restic" }}
          export RESTIC_PASSWORD="{{ .RESTIC_PASSWORD }}"
          export B2_ACCOUNT_ID="{{ .B2_ACCOUNT_ID }}"
          export B2_ACCOUNT_KEY="{{ .B2_ACCOUNT_KEY }}"
          {{ end }}

          # Use a single hostname
          export RESTIC_HOSTNAME="nas.elates.it"

          echo "Clean old backups"
          ./restic forget \
            --keep-last 1 \
            --keep-hourly 24 \
            --keep-daily 7 \
            --keep-weekly 12 \
            --keep-monthly 12 \
            --keep-yearly 5 \
            --keep-tag keep 
        EOF
      }

      volume_mount {
        volume      = "restic"
        destination = "/main/nfs/restic"
      }

      resources {
        cpu    = 1000
        memory = 256
      }
    }
  }
}
