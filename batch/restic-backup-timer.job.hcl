job "restic-backup-timer" {
  type     = "batch"
  priority = 70

  periodic {
    # Every third day at 2:05 to avoid clashing with :00 to avoid issues 
    crons            = ["05 2 */3 * *"]
    time_zone        = "CET"
    prohibit_overlap = true
  }

  affinity {
    attribute = node.class
    value     = "compute"
    weight    = "90"
  }

  group "trigger" {
    task "script" {
      driver       = "exec"

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
          #! /usr/bin/env nix-shell
          #! nix-shell -p bash coreutils nomad -i bash
          set -eux

          # Run Backups
          nomad job dispatch -detach -meta path_to_backup="/main/backups /main/personal /main/multimedia/Photos" restic-backup
        EOF
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
