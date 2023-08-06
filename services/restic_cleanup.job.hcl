job "restic_cleanup" {
  type = "batch"
  
  periodic {
    cron = "@daily"
    time_zone = "CET"
    prohibit_overlap = true
  }

  group "restic" {    
    task "restic" {
      driver = "exec"

      config {
        command = "/bin/bash"
        args = ["local/backup.sh"]
      }
      
      template {
        destination   = "local/backup.sh"
        change_mode   = "signal"
        change_signal = "SIGINT"
        perms = "0755"

        data = <<EOF
          #!/bin/bash -ex
          curl -L \
            --output restic.bz2 \
            https://github.com/restic/restic/releases/download/v0.16.0/restic_0.16.0_{{ env "attr.kernel.name" }}_{{ env "attr.cpu.arch" }}.bz2
          bunzip2 ./restic.bz2
          chmod +x ./restic

          ./restic self-update
          sleep 5

          {{ with nomadVar "nomad/jobs/restic_backups" }}
          export RESTIC_REPOSITORY="{{ .RESTIC_REPOSITORY }}"
          export RESTIC_PASSWORD="{{ .RESTIC_PASSWORD }}"
          export B2_ACCOUNT_ID="{{ .B2_ACCOUNT_ID }}"
          export B2_ACCOUNT_KEY="{{ .B2_ACCOUNT_KEY }}"
          {{ end }}

          # Use a single hostname
          export RESTIC_HOSTNAME="nas.elates.it"

          ./restic snapshots
          
          echo "Clean old backups"
          ./restic forget \
            --no-cache \
            --keep-last 1 \
            --keep-hourly 48 \
            --keep-daily 7 \
            --keep-weekly 12 \
            --keep-monthly 12 \
            --keep-yearly 5 \
            --keep-tag keep \
            --cleanup-cache

          echo "Check integrity"
          ./restic check --read-data-subset=0.1%
        EOF
      }

      resources {
        cpu    = 2000
        memory = 512
      }
    }    
  }
}
