job "restic-backup" {
  type     = "batch"
  priority = 73

  parameterized {
    meta_required = ["path_to_backup"]
    meta_optional = ["extra_flags"]
  }

  # Disable re-trying
  reschedule {
    attempts  = 0
    unlimited = false
  }

  group "restic" {
    constraint {
      operator  = "distinct_hosts"
      value     = "true"
    }
    
    task "restic" {
      driver       = "raw_exec"
      kill_timeout = "120s"

      config {
        command = "/bin/bash"
        args    = ["local/backup.sh"]
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
          echo "Startint backing up the backups in ${NOMAD_META_path_to_backup}"
          ${NOMAD_ALLOC_DIR}/restic backup ${NOMAD_META_path_to_backup} --host $RESTIC_HOSTNAME $RESTIC_COMMON_FLAGS ${NOMAD_META_extra_flags}
          sleep 1
        EOF
      }

      resources {
        cpu    = 1000
        memory = 1024
      }
    }

    volume "main-pool" {
      type      = "host"
      source    = "main-pool"
      read_only = true
    }
  }
}
