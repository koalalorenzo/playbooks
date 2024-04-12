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
        "traefik.udp.routers.iperf.entrypoints=iperf3-udp",
        "traefik.tcp.routers.iperf.rule=HostSNI(`*`)",
        "traefik.tcp.routers.iperf.entrypoints=iperf3-tcp",
      ]
    }

    task "iperf3" {
      driver       = "exec"
      kill_timeout = "10s"

      config {
        command = "/usr/bin/iperf3"
        args    = ["-s", "-p", "$${NOMAD_PORT_iperf3}"]
      }

      resources {
        cpu    = 256
        memory = 64
      }
    }

    affinity {
      attribute = node.class
      value     = "compute"
      weight    = 90
    }
  }
}



