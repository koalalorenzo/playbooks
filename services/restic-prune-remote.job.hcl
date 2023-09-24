job "restic-prune-remote" {
  type     = "batch"
  priority = 65

  periodic {
    crons            = ["@weekly"]
    time_zone        = "CET"
    prohibit_overlap = true
  }

  constraint {
    attribute = "${node.class}"
    value     = "compute"
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
          sleep 5

          {{ with nomadVar "nomad/jobs/restic" }}
          export RESTIC_REPOSITORY="{{ .RESTIC_REPOSITORY }}"
          export RESTIC_PASSWORD="{{ .RESTIC_PASSWORD }}"
          export B2_ACCOUNT_ID="{{ .B2_ACCOUNT_ID }}"
          export B2_ACCOUNT_KEY="{{ .B2_ACCOUNT_KEY }}"
          {{ end }}

          # Use a single hostname
          export RESTIC_HOSTNAME="nas.elates.it"

          # echo "Repair the index if needed"
          # ./restic repair index
          # ./restic repair snapshots --forget
        
          ./restic prune
        EOF
      }

      resources {
        cpu    = 1000
        memory = 256
      }
    }
  }
}
