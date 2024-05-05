{ config, lib, pkgs, boot, sops, ... }: {
  environment.etc = {
    "nomad.d/server.hcl" = {
      text = ''
        server {
          enabled = true
          bootstrap_expect = 3

          # Remove Nodes after this time
          node_gc_threshold = "6h"

          # How often should we run the GC?
          job_gc_interval = "1h"
          
          # What is the threshold for considering jobs ready to be cleaned?
          job_gc_threshold = "48h"

          csi_volume_claim_gc_interval = "15m"

          default_scheduler_config {
            scheduler_algorithm = "spread"
          }
        }
      '';
    };
  };
}

