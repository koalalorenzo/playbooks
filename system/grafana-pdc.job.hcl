job "grafana-pdc" {
  type     = "service"
  priority = 60

  group "pdc-agent" {
    task "pdc-agent" {
      driver       = "docker"
      kill_timeout = "60s"

      config {
        image = "grafana/pdc-agent:latest"
        args = [
          "-gcloud-hosted-grafana-id=${GCLOUD_HOSTED_GRAFANA_ID}",
          "-cluster=${GCLOUD_PDC_CLUSTER}",
          "-token=${GCLOUD_PDC_SIGNING_TOKEN}",
        ]
      }

      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
          {{- with nomadVar "nomad/jobs/grafana-pdc" -}}
          GCLOUD_HOSTED_GRAFANA_ID = "{{ .GRAFANA_HOSTED_ID }}"
          GCLOUD_PDC_CLUSTER = "{{ .GRAFANA_CLOUD_CLUSTER }}"
          GCLOUD_PDC_SIGNING_TOKEN = "{{ .GRAFANA_PDC_TOKEN }}"
          {{- end -}}
        EOF
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}

