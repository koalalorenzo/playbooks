# From: https://gitlab.com/rocketduck/csi-plugin-nfs
job "nfs-storage-node" {
  datacenters = ["dc1"]
  type        = "system"
  priority = 100

  group "node" {
    task "node" {
      driver = "docker"

      config {
        image = "registry.gitlab.com/rocketduck/csi-plugin-nfs:0.7.0"

        args = [
          "--type=node",
          "--node-id=${attr.unique.hostname}",
          "--nfs-server=192.168.197.151:/main/nfs",
          "--mount-options=defaults",
          "--allow-nested-volumes",
          "--log-level=DEBUG",
        ]

        network_mode = "host" 
        privileged = true
      }

      csi_plugin {
        id        = "nfs"
        type      = "node"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 500
        memory = 256
      }

    }
  }
}
