job "restic-backup-timer" {
  type     = "batch"
  priority = 70

  periodic {
    # Every third day at 2:05 to avoid clashing with :00 to avoid issues 
    crons            = ["05 2 */3 * *"]
    time_zone        = "CET"
    prohibit_overlap = true
  }

  group "trigger" {
    task "script" {
      driver       = "raw_exec"

      config {
        command = "/bin/bash"
        args    = ["local/run.sh"]
      }

      template {
        destination   = "local/run.sh"
        change_mode   = "signal"
        change_signal = "SIGINT"
        perms         = "0755"

        data = <<EOF
          #!/bin/bash
          set -eux

          # Run Backups
          nomad job dispatch -meta path_to_backup="/main/backups" restic-backup
          nomad job dispatch -meta path_to_backup="/main/personal" restic-backup
          nomad job dispatch -meta path_to_backup="/main/multimedia/Photos" restic-backup
        EOF
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
