job "blocky" {
  type     = "service"
  priority = 90

  group "resolver" {
    count = 2

    restart {
      delay    = "10s"
      interval = "30s"
      attempts = 3
    }

    # Reschedule the tasks somewhere else if they fail, max_delay of 1 minute
    reschedule {
      delay          = "15s"
      delay_function = "exponential"
      max_delay      = "1m"
      unlimited      = true
    }

    constraint {
      attribute = attr.cpu.arch
      value     = "arm64"
    }

    network {
      dns { servers = ["1.1.1.2", "1.0.0.1"] }
      port "http" {}
      port "dns" {}
    }

    service {
      name = "blocky-http"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.blocky.rule=Host(`blocky.elates.it`)",
        "traefik.http.routers.blocky.tls.certresolver=letsencrypt",
        "prometheus",
      ]

      check {
        name     = "blocky-http"
        type     = "http"
        path     = "/api/blocking/status"
        interval = "30s"
        timeout  = "5s"

        success_before_passing   = 1
        failures_before_critical = 3

        check_restart {
          limit = 3
          grace = "30s"
        }
      }

    }

    service {
      name = "blocky-dns"
      port = "dns"

      tags = [
        "traefik.enable=true",
        "traefik.udp.routers.blocky-dns.entrypoints=dns-udp",
      ]

      check {
        name     = "blicky-dns"
        type     = "tcp"
        interval = "20s"
        timeout  = "2s"

        success_before_passing   = 1
        failures_before_critical = 3

        check_restart {
          limit = 3
          grace = "30s"
        }
      }
    }

    task "dns" {
      driver       = "docker"
      kill_timeout = "30s"


      config {
        image       = "ghcr.io/0xerr0r/blocky:v0.24"
        force_pull  = false
        volumes     = ["local/config.yml:/app/config.yml"]
        ports       = ["http", "dns"]
        dns_servers = ["1.1.1.1", "1.0.0.1"]

        labels {
          persist_logs = "true"
        }

        # Disable docker's healthcheck as we change the port
        healthchecks {
          disable = true
        }
      }

      template {
        destination = "local/config.yml"
        change_mode = "restart"

        splay = "60s"
        data        = <<EOF
minTlsServeVersion: 1.3
upstreams:
  init:
    strategy: fast
  strategy: parallel_best
  groups:
    default:
      - https://security.cloudflare-dns.com/dns-query
      - https://base.dns.mullvad.net/dns-query
      - https://dns.quad9.net/dns-query
      - https://dns.nextdns.io/8bdcc5
bootstrapDns:
  - https://9.9.9.9/dns-query
  - https://1.1.1.2/dns-query
ports:
  dns: {{ env `NOMAD_PORT_dns` }}
  http: {{ env `NOMAD_PORT_http` }}
blocking:
  loading:
    strategy: fast
    concurrency: 2
    refreshPeriod: 12h
    maxErrorsPerSource: 5
    downloads:
      cooldown: 15s
      timeout: 1m
      attempts: 5
  blockType: nxDomain
  blockTTL: 12h
  allowlists:
    tracking: &generic_white_list
      - |
        /icloud.com/
        /apple.com/
        #/datadoghq.eu/
        #/static.datadoghq.com/
        /sentry/
        *.sentry-cdn.com
        /sentry.io/
        # GitHub Actions
        /github.com/
        /actions.githubusercontent.com/
        /blob.core.windows.net/
        /ghcr.io/
        /stats.grafana.org/
        /grafana.com/
        /grafana.net/
        /github-cloud.githubusercontent.com/
        /github-cloud.s3.amazonaws.com/
        # Videogames
        *.epicgames.dev
        *.epicgames.com
        /api.epicgames.dev/
        /epicgames.dev/
        /epicgames.com/
        /api.epicgames.dev/
        /on.epicgames.com/
        /cloud.unity3d.com/
        # Google
        /www.googleapis.com/
        /accounts.google.com/
        /calendar.google.com/
    ads: *generic_white_list
    malware: *generic_white_list
  denylists:
    # Some source: https://github.com/blocklistproject/Lists?tab=readme-ov-file#usage
    suspicious:
      - https://blocklistproject.github.io/Lists/basic.txt
      - https://blocklistproject.github.io/Lists/drugs.txt
      - https://blocklistproject.github.io/Lists/fraud.txt
      - https://blocklistproject.github.io/Lists/gambling.txt
      - https://blocklistproject.github.io/Lists/phishing.txt
      - https://blocklistproject.github.io/Lists/scam.txt
      - https://blocklistproject.github.io/Lists/smart-tv.txt
      - https://blocklistproject.github.io/Lists/tiktok.txt
      - https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts
      - https://raw.githubusercontent.com/matomo-org/referrer-spam-blacklist/master/spammers.txt
      - https://v.firebog.net/hosts/neohostsbasic.txt
      - https://v.firebog.net/hosts/static/w3kbl.txt
    ads:
      - https://adaway.org/hosts.txt
      - https://blocklistproject.github.io/Lists/ads.txt
      - https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext
      - https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts
      - https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt
      - https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts
      - https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts
      - https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
      - https://v.firebog.net/hosts/Admiral.txt
      - https://v.firebog.net/hosts/Easylist.txt
      - https://v.firebog.net/hosts/Easyprivacy.txt
      - https://v.firebog.net/hosts/Prigent-Ads.txt
      - |
        /fwtracks.freshmarketer.com/
        /realtime.luckyorange.com/
        /advertising-api-eu.amazon.com/
        /widgets.pinterest.com/
        /static.media.net/
        /adservetx.media.net/
        /adc3-launch.adcolony.com/
    piracy:
      - https://blocklistproject.github.io/Lists/piracy.txt
      - https://blocklistproject.github.io/Lists/torrent.txt
      - https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt
      - |
        /braflix/
        /broflix/
        /fmoviesz.to/
        /binged.in/
        /braflix.video/
        /braflix.co/
        /moviesjoy.is/
    tracking:
      - https://blocklistproject.github.io/Lists/tracking.txt
      - https://blocklistproject.github.io/Lists/adobe.txt
      - https://gist.githubusercontent.com/eterps/9ddb13a118a21a7d9c12c6165e0bbff5/raw/0ba4b04802a4b478d7777fb7abe76c8eac0c5bfc/Samsung%2520Smart-TV%2520Blocklist%2520Adlist%2520(for%2520PiHole)
      - https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt
      - https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts
      - https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/AmazonFireTV.txt
      - https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt
      - https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/android-tracking.txt
      - https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt
      - https://small.oisd.nl/domainswild
      - https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt
      - |
        /realme.com/
        /mouseflow.com/
        /app-measurement.com/
        /smetrics.samsung.com/
        /samsung-com.112.2o7.net/
        /hicloud.com/
        /metrics.data.hicloud.com/
        /metrics2.data.hicloud.com/
        /metrics3.data.hicloud.com/
        /grs.hicloud.com/
        /upload.luckyorange.net/
        /logservice.hicloud.com/
        /logservice1.hicloud.com/
        /fwtracks.freshmarketer.com/
        /logbak.hicloud.com/
        /notify.bugsnag.com/
        /app.getsentry.com/
        /pixel.facebook.com/
        /events.reddit.com/
        /trk.pinterest.com/
        /adfstat.yandex.ru/
        /tracking.rus.miui.com/
        /data.mistat.xiaomi.com/
        /hotjar.com/
        /insights.hotjar.com/
        /intercom.io/
        /samsungqbe.com/
    malware:
      - https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt
      - https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt
      - https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt
      - https://phishing.army/download/phishing_army_blocklist_extended.txt
      - https://blocklistproject.github.io/Lists/malware.txt
      - https://blocklistproject.github.io/Lists/ransomware.txt

  clientGroupsBlock:
    default:
      - ads
      - suspicious
      - tracking
      - malware
caching:
  minTime: 30m
  maxTime: 12h
  maxItemsCount: 16384
  cacheTimeNegative: 5m
  prefetching: true
  # Prefetch a domain if it has more than 30 requests in 3h.
  prefetchExpires: 3h
  prefetchThreshold: 30
  prefetchMaxItemsCount: 512
{{ range $index, $element := service "postgres" }}{{if eq $index 0}}
queryLog:
  type: postgresql
  logRetentionDays: 90
  target: postgres://{{ with nomadVar "nomad/jobs/blocky" }}{{ .POSTGRES_USERNAME }}:{{ .POSTGRES_PASSWORD }}{{ end }}@{{ .Address }}:{{ .Port }}/blocky?sslmode=disable
{{ end }}{{ end }}
prometheus:
  enable: true
  path: /metrics
{{ range service "redis" }}
redis:
  required: false
  address: {{ .Address }}:{{ .Port }}
{{ end }}
log:
  level: warn
  timestamp: true
  privacy: false
connectIPVersion: v4
filtering:
  queryTypes:
    - AAAA
EOF
      }


      resources {
        cpu    = 512
        memory = 256
      }
    }

    constraint {
      operator = "distinct_hosts"
      value    = "true"
    }

    affinity {
      attribute = node.class
      value     = "compute"
      weight    = 90
    }
  }

  # Manual updates 
  update {
    max_parallel     = 1
    canary           = 1
    min_healthy_time = "1m"
    healthy_deadline = "3m"
    auto_revert      = true
    auto_promote     = true
  }

  # Migrations during node draining
  migrate {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "1m"
    healthy_deadline = "3m"
  }
}
