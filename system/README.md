# Nomad tasks 
This directory contains nomad configuration to deploy system services necessary
for other workloads to run. This includes controllers, load balancing / ingress
and various other tools.

They are intended to have **higher priority** then other tasks. (above 80)
