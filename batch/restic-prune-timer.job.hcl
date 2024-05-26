job "restic-prune-timer" {
  type     = "batch"
  priority = 70

  periodic {
    crons            = ["@weekly"]
    time_zone        = "CET"
    prohibit_overlap = true
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
          #!/bin/bash
          set -eux

          nomad job dispatch -meta repository="b2:restic-koalalorenzo:/" restic-prune
          nomad job dispatch -meta repository="rest:https://restic.elates.it" restic-prune
        EOF
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
