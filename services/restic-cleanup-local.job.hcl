job "restic-cleanup-local" {
  type     = "batch"
  priority = 60

  periodic {
    crons            = ["@daily"]
    time_zone        = "CET"
    prohibit_overlap = true
  }

  constraint {
    attribute = node.class
    value     = "compute"
  }

  group "restic" {
    task "restic" {
      driver       = "exec"
      kill_timeout = "60s"


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
          {{ with nomadVar "nomad/jobs/restic" }}
          export RESTIC_VERSION="{{ .RESTIC_VERSION }}"
          export RESTIC_PASSWORD="{{ .RESTIC_PASSWORD }}"
          export B2_ACCOUNT_ID="{{ .B2_ACCOUNT_ID }}"
          export B2_ACCOUNT_KEY="{{ .B2_ACCOUNT_KEY }}"
          {{ end }}

          set -exu
          curl -L \
            --output restic.bz2 \
            https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_{{ env "attr.kernel.name" }}_{{ env "attr.cpu.arch" }}.bz2
          bunzip2 ./restic.bz2
          chmod +x ./restic

          ./restic self-update
          sleep 3

          export RESTIC_REPOSITORY="rest:https://restic.elates.it"
        
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

      resources {
        cpu    = 1500
        memory = 1024
      }
    }
  }
}
