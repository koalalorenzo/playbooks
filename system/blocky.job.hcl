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

    constraint {
      attribute = meta.run_dns
      value     = "true"
    }

    network {
      dns { servers = ["1.1.1.2", "1.0.0.1"] }
      port "http" {}
      port "dns" {
        static = 53
      }
    }

    service {
      provider = "nomad"
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

        check_restart {
          limit = 3
          grace = "30s"
        }
      }

    }

    service {
      provider = "nomad"
      name = "blocky-dns"
      port = "dns"

      check {
        name     = "blocky-dns"
        type     = "tcp"
        interval = "20s"
        timeout  = "2s"

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
        dns_servers = ["1.1.1.2", "1.0.0.1"]
        
        network_mode = "host"

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
    refreshPeriod: 8h
    maxErrorsPerSource: 15
    downloads:
      cooldown: 2s
      timeout: 15s
      attempts: 5
  blockType: nxDomain
  blockTTL: 12h
  allowlists:
    tracking: &generic_white_list
      - |
        # Pete's work
        /twentythree.systems/
        *.twentythree.systems
        /staging.twentythree.systems/
        *.staging.twentythree.systems
        /rds.amazonaws.com/
        *.rds.amazonaws.com
        # Generic
        *.arpa
        /.arpa$/
        /icloud.com/
        /apple.com/
        #/datadoghq.eu/
        #/static.datadoghq.com/
        /sentry/
        *.sentry-cdn.com
        /sentry.io/
        # GitHub Actions and automations
        /github.com/
        /actions.githubusercontent.com/
        /blob.core.windows.net/
        /ghcr.io/
        /stats.grafana.org/
        /grafana.com/
        /grafana.net/
        /github-cloud.githubusercontent.com/
        /github-cloud.s3.amazonaws.com/
        docker.n8n.io
        # Videogames
        *.epicgames.dev
        *.epicgames.com
        /api.epicgames.dev/
        /epicgames.dev/
        /epicgames.com/
        /api.epicgames.dev/
        /on.epicgames.com/
        /registry.heroiclabs.com/
        *.heroiclabs.com
        /cloud.unity3d.com/
        # Google
        /www.googleapis.com/
        /accounts.google.com/
        /calendar.google.com/
        # LEGO
        /sway.cloud.microsoft/
    ads: *generic_white_list
    malware: *generic_white_list
    piracy: *generic_white_list
    suspicious: *generic_white_list
  denylists:
    # Some source: https://github.com/blocklistproject/Lists?tab=readme-ov-file#usage
    suspicious:
      - https://blocklistproject.github.io/Lists/alt-version/abuse-nl.txt
      - https://blocklistproject.github.io/Lists/alt-version/drugs-nl.txt
      - https://blocklistproject.github.io/Lists/alt-version/fraud-nl.txt
      - https://blocklistproject.github.io/Lists/alt-version/gambling-nl.txt
      - https://blocklistproject.github.io/Lists/alt-version/scam-nl.txt
      - https://blocklistproject.github.io/Lists/alt-version/vaping-nl.txt
      - https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts
      - https://raw.githubusercontent.com/matomo-org/referrer-spam-blacklist/master/spammers.txt
      - https://v.firebog.net/hosts/neohostsbasic.txt
      - https://v.firebog.net/hosts/static/w3kbl.txt
      - /snapchat.com/
      - /snap.com/
      - /snapchat.appspot.com/
      - /sc-analytics.appspot.com/
      - /feelinsonice-hrd.appspot.com/
      - /www.feelinsonice.com/
    ads:
      - https://adaway.org/hosts.txt
      - https://blocklistproject.github.io/Lists/alt-version/ads-nl.txt
      - https://blocklistproject.github.io/Lists/alt-version/smart-tv-nl.txt
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
      - https://blocklistproject.github.io/Lists/alt-version/piracy-nl.txt
      - https://blocklistproject.github.io/Lists/alt-version/torrent-nl.txt
      - https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt
      - |
        /braflix/
        /broflix/
        /fmoviesz.to/
        /binged.in/
        /braflix.video/
        /braflix.co/
        /braflix.so/
        /moviesjoy.is/
    tracking:
      - https://blocklistproject.github.io/Lists/alt-version/tracking-nl.txt
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
      - https://blocklistproject.github.io/Lists/alt-version/malware-nl.txt
      - https://blocklistproject.github.io/Lists/alt-version/phishing-nl.txt
      - https://blocklistproject.github.io/Lists/alt-version/ransomware-nl.txt
      - https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt
      - https://phishing.army/download/phishing_army_blocklist_extended.txt
      - https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt
  clientGroupsBlock:
    default:
      - ads
      - suspicious
      - piracy
      - tracking
      - malware
caching:
  minTime: 1h
  maxTime: 12h
  maxItemsCount: 16384
  cacheTimeNegative: 15m
  prefetching: false
  # Prefetch a domain if it has more than 30 requests in 1h.
  prefetchExpires: 1h
  prefetchThreshold: 30
  prefetchMaxItemsCount: 512

clientLookup:
  upstream: 192.168.197.1
  clients:
    lorenzo-mbp:
      - 192.168.197.26
      - 100.111.226.22
    storage0:
      - 192.168.197.2
      - 192.168.197.5
      - 100.100.180.12
    compute0:
      - 192.168.197.4
      - 100.98.104.116
    compute1:
      - 100.77.141.108
      - 192.168.197.3
    compute2:
      - 100.114.69.32
      - 192.168.197.6
    appletv:
      - 100.67.248.58
      - 192.168.197.142
      - 192.168.197.102

{{ range $index, $element := service "postgres" }}{{if eq $index 0}}
queryLog:
  type: postgresql
  logRetentionDays: 90
  target: postgres://{{ with nomadVar "nomad/jobs/blocky" }}{{ .POSTGRES_USERNAME }}:{{ .POSTGRES_PASSWORD }}{{ end }}@{{ .Address }}:{{ .Port }}/blocky?sslmode=disable
{{ end }}{{ end }}
prometheus:
  enable: true
  path: /metrics
{{ range $index, $element := service "redis" }}{{if eq $index 0}}
redis:
  required: false
  address: {{ .Address }}:{{ .Port }}
{{ end }}{{ end }}
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
  # update {
  #   max_parallel     = 1
  #   canary           = 1
  #   min_healthy_time = "1m"
  #   healthy_deadline = "3m"
  #   auto_revert      = true
  #   auto_promote     = true
  # }

  # # Migrations during node draining
  # migrate {
  #   max_parallel     = 1
  #   health_check     = "checks"
  #   min_healthy_time = "1m"
  #   healthy_deadline = "3m"
  # }
}
