job "restic-prune-parametized" {
  type     = "batch"
  priority = 65

  parameterized {
    payload       = "required"
    meta_required = ["RESTIC_REPOSITORY"]
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
          RESTIC_COMMON_FLAGS="{{ .RESTIC_COMMON_FLAGS }}"
          {{ end }}
          
          RESTIC_HOSTNAME="nas.elates.it"
          RESTIC_REPOSITORY="{{ env `NOMAD_META_RESTIC_REPOSITORY` }}"
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

          # echo "Repair the index if needed"
          # ${NOMAD_ALLOC_DIR}/restic repair index
          # ${NOMAD_ALLOC_DIR}/restic repair snapshots --forget
        
          ${NOMAD_ALLOC_DIR}/restic prune $RESTIC_COMMON_FLAGS
        EOF
      }

      resources {
        cpu    = 1500
        memory = 1024
      }
    }
  }
}
