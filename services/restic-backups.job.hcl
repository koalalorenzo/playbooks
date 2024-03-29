job "restic-backups" {
  type     = "batch"
  priority = 70

  periodic {
    crons            = ["0 2 * * 1,5"]
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

      volume_mount {
        volume      = "personal"
        destination = "/main/personal"
      }

      volume_mount {
        volume      = "backups"
        destination = "/main/backups"
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
          {{ end }}

          set -exu
          curl -L \
            --output restic.bz2 \
            https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_{{ env "attr.kernel.name" }}_{{ env "attr.cpu.arch" }}.bz2
          bunzip2 ./restic.bz2
          chmod +x ./restic

          ./restic self-update
          sleep 3

          # Use a single hostname
          export RESTIC_HOSTNAME="nas.elates.it"
          
          echo "Startint backing up the backups"
          ./restic backup /main/backups --host $RESTIC_HOSTNAME
          sleep 5
          echo "Starting backing up personal files"
          ./restic backup /main/personal --host $RESTIC_HOSTNAME
        EOF
      }

      resources {
        cpu    = 2000
        memory = 1024
      }
    }

    volume "backups" {
      type      = "host"
      source    = "backups"
      read_only = true
    }

    volume "personal" {
      type      = "host"
      source    = "personal"
      read_only = true
    }
  }
}
