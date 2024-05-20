job "restic-prune-remote" {
  type     = "batch"
  priority = 65

  periodic {
    crons            = ["@weekly"]
    time_zone        = "CET"
    prohibit_overlap = true
  }

  affinity {
    attribute = meta.run_batch
    value     = "true"
    weight    = 90
  }

  group "restic" {
    task "restic" {
      driver       = "exec"
      kill_timeout = "300s"

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
          #!/bin/bash
          {{ with nomadVar "nomad/jobs/restic" }}
          export RESTIC_VERSION="{{ .RESTIC_VERSION }}"
          export RESTIC_PASSWORD="{{ .RESTIC_PASSWORD }}"
          export B2_ACCOUNT_ID="{{ .B2_ACCOUNT_ID }}"
          export B2_ACCOUNT_KEY="{{ .B2_ACCOUNT_KEY }}"
          export RESTIC_REPOSITORY="{{ .RESTIC_REPOSITORY }}"
          export RESTIC_COMMON_FLAGS="{{ .RESTIC_COMMON_FLAGS }}"
          {{ end }}
        
          set -exu
          curl -L \
            --output restic.bz2 \
            https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_{{ env "attr.kernel.name" }}_{{ env "attr.cpu.arch" }}.bz2
          bunzip2 ./restic.bz2
          chmod +x ./restic

          ./restic self-update
          sleep 5

          # Use a single hostname
          export RESTIC_HOSTNAME="nas.elates.it"

          # echo "Repair the index if needed"
          # ./restic repair index
          # ./restic repair snapshots --forget
        
          ./restic prune $RESTIC_COMMON_FLAGS
        EOF
      }

      resources {
        cpu    = 1500
        memory = 1024
      }
    }
  }
}
