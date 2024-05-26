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
      driver       = "exec"
      kill_timeout = "120s"

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

      artifact {
        source = "https://github.com/restic/restic/releases/download/v0.16.4/restic_0.16.4_${attr.kernel.name}_${attr.cpu.arch}.bz2"
        destination = "${NOMAD_ALLOC_DIR}/"

        options {
          archive = false
        }
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOH
          {{ with nomadVar "nomad/jobs/restic" }}
          RESTIC_PASSWORD="{{ .RESTIC_PASSWORD }}"
          B2_ACCOUNT_ID="{{ .B2_ACCOUNT_ID }}"
          B2_ACCOUNT_KEY="{{ .B2_ACCOUNT_KEY }}"
          RESTIC_REPOSITORY="{{ .RESTIC_REPOSITORY }}"
          RESTIC_COMMON_FLAGS="{{ .RESTIC_COMMON_FLAGS }}"
          {{ end }}
          
          RESTIC_HOSTNAME="nas.elates.it"
        EOH
      }

      template {
        destination   = "local/backup.sh"
        change_mode   = "signal"
        change_signal = "SIGINT"
        perms         = "0755"

        data = <<EOF
          #!/bin/bash
          if [ ! -e "${NOMAD_ALLOC_DIR}/restic" ]; then
            bunzip2 ${NOMAD_ALLOC_DIR}/restic*.bz2
            mv ${NOMAD_ALLOC_DIR}/restic* ${NOMAD_ALLOC_DIR}/restic
            chmod +x ${NOMAD_ALLOC_DIR}/restic
          fi
          set -exu
          
          ${NOMAD_ALLOC_DIR}/restic self-update

          echo "Startint backing up the backups"
          ${NOMAD_ALLOC_DIR}/restic backup /main/backups --host $RESTIC_HOSTNAME $RESTIC_COMMON_FLAGS
          sleep 5

          echo "Starting backing up personal files"
          ${NOMAD_ALLOC_DIR}/restic backup /main/personal --host $RESTIC_HOSTNAME $RESTIC_COMMON_FLAGS
          sleep 300
        EOF
      }

      resources {
        cpu    = 1000
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
