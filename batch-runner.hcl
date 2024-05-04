datacenter = "dc1"
bind_addr = "0.0.0.0"

log_rotate_duration = "24h"
log_rotate_max_files = 7

telemetry {
 collection_interval = "60s" # Must match or less than prometheus scrape_interval
 publish_allocation_metrics = true
 publish_node_metrics = true
 prometheus_metrics = true
}

ui {
  enabled = true
  consul {
    ui_url = "http://consul.elates.it/ui"
  }
}

consul {
  address = "storage0:8500"

  # The service name to register the server and client with Consul.
  server_service_name = "nomad"
  client_service_name = "nomad-client"
  auto_advertise = true
  server_auto_join = true
  client_auto_join = true
}

client {
  enabled = true

  gc_interval = "5m"

  # Uses Tailscale as network interface
  network_interface = "utun8"

  node_class = "batch"
  
  options = {
    "driver.denylist" = "java"
  }

  servers = ["storage0", "compute1", "compute0"]

  host_volume "ca-certificates" {
    path = "/etc/ssl/certs"
    read_only = true
  }

  reserved {
    cpu    = 2000
    memory = 4048
  }

  artifact {
    disable_filesystem_isolation = true
  }
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

plugin "docker" {
  config {
    allow_privileged = true

    gc {
      image       = true
      image_delay = "72h"
      container   = true
    }

    volumes {
      enabled = true
    }
  }
}
