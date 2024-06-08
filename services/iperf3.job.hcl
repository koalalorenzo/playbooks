job "iperf3" {
  type = "service"

  group "server" {
    count = 1

    network {
      port "iperf3" {}
    }

    service {
      name = "iperf3"
      port = "iperf3"

      tags = [
        "traefik.enable=true",
        "traefik.udp.routers.iperf.entrypoints=iperf-udp",
        "traefik.tcp.routers.iperf.rule=HostSNI(`*`)",
        "traefik.tcp.routers.iperf.entrypoints=iperf-tcp",
      ]

      check {
        name     = "iperf3"
        type     = "tcp"
        interval = "60s"
        timeout  = "5s"

        success_before_passing   = 1
        failures_before_critical = 3

        check_restart {
          grace = "10s"
        }
      }

    }

    task "iperf3" {
      driver       = "exec"
      kill_timeout = "10s"

      config {
        command = "/usr/bin/iperf3"
        args    = ["-s", "-p", "$${NOMAD_PORT_iperf3}"]
      }

      resources {
        cpu    = 64
        memory = 16
      }
    }

    affinity {
      attribute = node.class
      value     = "compute"
      weight    = 90
    }
  }
}



