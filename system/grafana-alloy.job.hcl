job "grafana" {
  type     = "system"
  priority = 90

  group "alloy" {
    update {
      max_parallel     = 1
      health_check     = "checks"
      min_healthy_time = "60s"
      healthy_deadline = "5m"
    }

    restart {
      delay    = "5s"
      interval = "5m"
      attempts = 55
      mode     = "delay"
    }

    network {
      port "http" {
        static = 27373
      }
    }

    service {
      name = "alloy"
      port = "http"

      # check {
      #   name     = "alive"
      #   type     = "tcp"
      #   port     = "http"
      #   interval = "30s"
      #   timeout  = "15s"
      # }

      tags = [
        "traefik.enable=false",
      ]
    }

    task "alloy" {
      driver       = "docker"
      kill_timeout = "30s"

      config {
        image = "grafana/alloy:latest"
        args = [
          "run",
          "--server.http.listen-addr=0.0.0.0:${NOMAD_PORT_http}",
          "--server.http.enable-pprof=false",
          "--cluster.enabled=true",
          "--cluster.join-addresses=192.168.197.3:${NOMAD_PORT_http},192.168.197.4:${NOMAD_PORT_http},192.168.197.5:${NOMAD_PORT_http}",
          "--cluster.rejoin-interval=3600s", # Avoid split brain issues
          "--cluster.advertise-address=${NOMAD_ADDR_http}",
          "--cluster.name=elates.it",
          "--storage.path=/var/lib/alloy/data",
          "/etc/alloy/config.alloy"
        ]

        ports = ["http"]

        volumes = [
          "local/config.alloy:/etc/alloy/config.alloy",
          "/var/run/docker.sock:/var/run/docker.sock",
          "/var/logs:/var/logs:ro",
        ]
      }


      template {
        destination = "local/config.alloy"
        data        = <<EOF
          logging {
            level  = "info"
            format = "logfmt"
          }

          prometheus.exporter.self "integrations_alloy" { }

          discovery.relabel "integrations_alloy" {
            targets = prometheus.exporter.self.integrations_alloy.targets

            rule {
              target_label = "instance"
              replacement  = "{{ env "attr.unique.hostname" }}"
            }

            rule {
              target_label = "alloy_hostname"
              replacement  = "{{ env "attr.unique.hostname" }}"
            }

            rule {
              target_label = "job"
              replacement  = "integrations/alloy-check"
            }
          }

          prometheus.scrape "integrations_alloy" {
            targets    = discovery.relabel.integrations_alloy.output
            forward_to = [prometheus.relabel.integrations_alloy.receiver]  

            scrape_interval = "60s"
          }

          prometheus.relabel "integrations_alloy" {
            forward_to = [prometheus.remote_write.metrics_service.receiver]

            rule {
              source_labels = ["__name__"]
              regex         = "(prometheus_target_sync_length_seconds_sum|prometheus_target_scrapes_.*|prometheus_target_interval.*|prometheus_sd_discovered_targets|alloy_build.*|prometheus_remote_write_wal_samples_appended_total|process_start_time_seconds)"
              action        = "keep"
            }
          }


          prometheus.remote_write "metrics_service" {
              endpoint {
                  {{- with nomadVar "nomad/jobs/grafana" -}}
                  url = "{{ .GCLOUD_HOSTED_METRICS_URL }}"
                  basic_auth {
                      username = "{{ .GCLOUD_HOSTED_METRICS_ID }}"
                      password = "{{ .GCLOUD_RW_API_KEY }}"
                  }
                  {{- end -}}
              }
          }

          loki.write "grafana_cloud_loki" {
            endpoint {
              {{- with nomadVar "nomad/jobs/grafana" -}}
              url = "{{ .GCLOUD_HOSTED_LOGS_URL }}"

              basic_auth {
                username = "{{ .GCLOUD_HOSTED_LOGS_ID }}"
                password = "{{ .GCLOUD_RW_API_KEY }}"
              }
              {{- end -}}
            }
          }


          // From UI of Grafana Cloud

          discovery.relabel "integrations_node_exporter" {
            targets = prometheus.exporter.unix.integrations_node_exporter.targets

            rule {
              target_label = "instance"
              replacement  = "{{ env "attr.unique.hostname" }}"
            }

            rule {
              target_label = "job"
              replacement = "integrations/node_exporter"
            }
          }

          prometheus.exporter.unix "integrations_node_exporter" {
            disable_collectors = ["ipvs", "btrfs", "infiniband", "xfs", "zfs"]

            filesystem {
              fs_types_exclude     = "^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|tmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"
              mount_points_exclude = "^/(dev|proc|run/credentials/.+|sys|var/lib/docker/.+)($|/)"
              mount_timeout        = "5s"
            }

            netclass {
              ignored_devices = "^(veth.*|cali.*|[a-f0-9]{15})$"
            }

            netdev {
              device_exclude = "^(veth.*|cali.*|[a-f0-9]{15})$"
            }
          }

          prometheus.scrape "integrations_node_exporter" {
            targets    = discovery.relabel.integrations_node_exporter.output
            forward_to = [prometheus.relabel.integrations_node_exporter.receiver]
          }

          prometheus.relabel "integrations_node_exporter" {
            forward_to = [prometheus.remote_write.metrics_service.receiver]
  
            rule {
              source_labels = ["__name__"]
              regex         = "up|node_arp_entries|node_boot_time_seconds|node_context_switches_total|node_cpu_seconds_total|node_disk_io_time_seconds_total|node_disk_io_time_weighted_seconds_total|node_disk_read_bytes_total|node_disk_read_time_seconds_total|node_disk_reads_completed_total|node_disk_write_time_seconds_total|node_disk_writes_completed_total|node_disk_written_bytes_total|node_filefd_allocated|node_filefd_maximum|node_filesystem_avail_bytes|node_filesystem_device_error|node_filesystem_files|node_filesystem_files_free|node_filesystem_readonly|node_filesystem_size_bytes|node_intr_total|node_load1|node_load15|node_load5|node_md_disks|node_md_disks_required|node_memory_Active_anon_bytes|node_memory_Active_bytes|node_memory_Active_file_bytes|node_memory_AnonHugePages_bytes|node_memory_AnonPages_bytes|node_memory_Bounce_bytes|node_memory_Buffers_bytes|node_memory_Cached_bytes|node_memory_CommitLimit_bytes|node_memory_Committed_AS_bytes|node_memory_DirectMap1G_bytes|node_memory_DirectMap2M_bytes|node_memory_DirectMap4k_bytes|node_memory_Dirty_bytes|node_memory_HugePages_Free|node_memory_HugePages_Rsvd|node_memory_HugePages_Surp|node_memory_HugePages_Total|node_memory_Hugepagesize_bytes|node_memory_Inactive_anon_bytes|node_memory_Inactive_bytes|node_memory_Inactive_file_bytes|node_memory_Mapped_bytes|node_memory_MemAvailable_bytes|node_memory_MemFree_bytes|node_memory_MemTotal_bytes|node_memory_SReclaimable_bytes|node_memory_SUnreclaim_bytes|node_memory_ShmemHugePages_bytes|node_memory_ShmemPmdMapped_bytes|node_memory_Shmem_bytes|node_memory_Slab_bytes|node_memory_SwapTotal_bytes|node_memory_VmallocChunk_bytes|node_memory_VmallocTotal_bytes|node_memory_VmallocUsed_bytes|node_memory_WritebackTmp_bytes|node_memory_Writeback_bytes|node_netstat_Icmp6_InErrors|node_netstat_Icmp6_InMsgs|node_netstat_Icmp6_OutMsgs|node_netstat_Icmp_InErrors|node_netstat_Icmp_InMsgs|node_netstat_Icmp_OutMsgs|node_netstat_IpExt_InOctets|node_netstat_IpExt_OutOctets|node_netstat_TcpExt_ListenDrops|node_netstat_TcpExt_ListenOverflows|node_netstat_TcpExt_TCPSynRetrans|node_netstat_Tcp_InErrs|node_netstat_Tcp_InSegs|node_netstat_Tcp_OutRsts|node_netstat_Tcp_OutSegs|node_netstat_Tcp_RetransSegs|node_netstat_Udp6_InDatagrams|node_netstat_Udp6_InErrors|node_netstat_Udp6_NoPorts|node_netstat_Udp6_OutDatagrams|node_netstat_Udp6_RcvbufErrors|node_netstat_Udp6_SndbufErrors|node_netstat_UdpLite_InErrors|node_netstat_Udp_InDatagrams|node_netstat_Udp_InErrors|node_netstat_Udp_NoPorts|node_netstat_Udp_OutDatagrams|node_netstat_Udp_RcvbufErrors|node_netstat_Udp_SndbufErrors|node_network_carrier|node_network_info|node_network_mtu_bytes|node_network_receive_bytes_total|node_network_receive_compressed_total|node_network_receive_drop_total|node_network_receive_errs_total|node_network_receive_fifo_total|node_network_receive_multicast_total|node_network_receive_packets_total|node_network_speed_bytes|node_network_transmit_bytes_total|node_network_transmit_compressed_total|node_network_transmit_drop_total|node_network_transmit_errs_total|node_network_transmit_fifo_total|node_network_transmit_multicast_total|node_network_transmit_packets_total|node_network_transmit_queue_length|node_network_up|node_nf_conntrack_entries|node_nf_conntrack_entries_limit|node_os_info|node_sockstat_FRAG6_inuse|node_sockstat_FRAG_inuse|node_sockstat_RAW6_inuse|node_sockstat_RAW_inuse|node_sockstat_TCP6_inuse|node_sockstat_TCP_alloc|node_sockstat_TCP_inuse|node_sockstat_TCP_mem|node_sockstat_TCP_mem_bytes|node_sockstat_TCP_orphan|node_sockstat_TCP_tw|node_sockstat_UDP6_inuse|node_sockstat_UDPLITE6_inuse|node_sockstat_UDPLITE_inuse|node_sockstat_UDP_inuse|node_sockstat_UDP_mem|node_sockstat_UDP_mem_bytes|node_sockstat_sockets_used|node_softnet_dropped_total|node_softnet_processed_total|node_softnet_times_squeezed_total|node_systemd_unit_state|node_textfile_scrape_error|node_time_zone_offset_seconds|node_timex_estimated_error_seconds|node_timex_maxerror_seconds|node_timex_offset_seconds|node_timex_sync_status|node_uname_info|node_vmstat_oom_kill|node_vmstat_pgfault|node_vmstat_pgmajfault|node_vmstat_pgpgin|node_vmstat_pgpgout|node_vmstat_pswpin|node_vmstat_pswpout|process_max_fds|process_open_fds"
              action        = "keep"
            }
          }

          loki.source.journal "logs_integrations_integrations_node_exporter_journal_scrape" {
            max_age       = "24h0m0s"
            relabel_rules = discovery.relabel.logs_integrations_integrations_node_exporter_journal_scrape.rules
            forward_to    = [loki.write.grafana_cloud_loki.receiver]
          }

          local.file_match "logs_integrations_integrations_node_exporter_direct_scrape" {
            path_targets = [{
              __address__ = "localhost",
              __path__    = "/var/log/{syslog,messages,*.log}",
              instance    = "{{ env "attr.unique.hostname" }}",
              job         = "integrations/node_exporter",
            }]
          }

          discovery.relabel "logs_integrations_integrations_node_exporter_journal_scrape" {
            targets = []

            rule {
              source_labels = ["__journal__systemd_unit"]
              target_label  = "unit"
            }

            rule {
              source_labels = ["__journal__boot_id"]
              target_label  = "boot_id"
            }

            rule {
              source_labels = ["__journal__transport"]
              target_label  = "transport"
            }

            rule {
              source_labels = ["__journal_priority_keyword"]
              target_label  = "level"
            }
          }

          loki.source.file "logs_integrations_integrations_node_exporter_direct_scrape" {
            targets    = local.file_match.logs_integrations_integrations_node_exporter_direct_scrape.targets
            forward_to = [loki.write.grafana_cloud_loki.receiver]
          }


          // Docker Integration

          prometheus.exporter.cadvisor "integrations_cadvisor" {
              docker_only = true
          }
          
          discovery.relabel "integrations_cadvisor" {
              targets = prometheus.exporter.cadvisor.integrations_cadvisor.targets

              rule {
                  target_label = "job"
                  replacement  = "integrations/docker"
              }

              rule {
                  target_label = "instance"
                  replacement  = "{{ env "attr.unique.hostname" }}"
              }

              rule {
            		source_labels = ["__name__"]
            		regex         = "up|container_cpu_usage_seconds_total|container_fs_inodes_free|container_fs_inodes_total|container_fs_limit_bytes|container_fs_usage_bytes|container_last_seen|container_memory_usage_bytes|container_network_receive_bytes_total|container_network_tcp_usage_total|container_network_transmit_bytes_total|container_spec_memory_reservation_limit_bytes|machine_memory_bytes|machine_scrape_error"
            		action        = "keep"
            	}
          }
          
          prometheus.scrape "integrations_cadvisor" {
              targets    = discovery.relabel.integrations_cadvisor.output
              forward_to = [prometheus.remote_write.metrics_service.receiver]
          }

          discovery.docker "logs_integrations_docker" {
              host             = "unix:///var/run/docker.sock"
              refresh_interval = "10s"
          }
          
          discovery.relabel "logs_integrations_docker" {
              targets = []

              rule {
                  target_label = "job"
                  replacement  = "integrations/docker"
              }

              rule {
                  target_label = "instance"
                  replacement  = "{{ env "attr.unique.hostname" }}"
              }

              rule {
                  source_labels = ["__meta_docker_container_name"]
                  regex         = "/(.*)"
                  target_label  = "container"
              }

              rule {
                  source_labels = ["__meta_docker_container_log_stream"]
                  target_label  = "stream"
              }
          }

          loki.source.docker "logs_integrations_docker" {
              host             = "unix:///var/run/docker.sock"
              targets          = discovery.docker.logs_integrations_docker.targets
              forward_to       = [loki.write.grafana_cloud_loki.receiver]
              relabel_rules    = discovery.relabel.logs_integrations_docker.rules
              refresh_interval = "10s"
          }

          // Consul Discovery

          discovery.consul "consul_discovery" {
             server = "https://consul.elates.it"
             tags   = ["prometheus"]
             refresh_interval = "60s"
          }

          prometheus.scrape "consul_discovery" {
              targets    = discovery.consul.consul_discovery.targets
              forward_to = [prometheus.remote_write.metrics_service.receiver]
          }

          // Consul Integration
          prometheus.exporter.consul "integrations_consul_exporter" {
             server = "https://consul.elates.it"
          }

          discovery.relabel "integrations_consul_exporter" {
          	targets = prometheus.exporter.consul.integrations_consul_exporter.targets

          	rule {
          		target_label = "instance"
          		replacement  = "{{ env "attr.unique.hostname" }}"
          	}

          	rule {
          		target_label = "job"
          		replacement  = "integrations/consul"
          	}
          }

          prometheus.scrape "integrations_consul_exporter" {
          	targets    = discovery.relabel.integrations_consul_exporter.output
          	forward_to = [prometheus.relabel.integrations_consul_exporter.receiver]
          	job_name   = "integrations/consul_exporter"
          }

          prometheus.relabel "integrations_consul_exporter" {
          	forward_to = [prometheus.remote_write.metrics_service.receiver]

          	rule {
          		source_labels = ["__name__"]
          		regex         = "up|consul_raft_leader|consul_raft_leader_lastcontact_count|consul_raft_peers|consul_up"
          		action        = "keep"
          	}
          }

        EOF
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
