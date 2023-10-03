job "blocky" {
  type     = "service"
  priority = 90

  group "resolver" {
    count = 2

    restart {
      delay    = "5s"
      interval = "20s"
      attempts = 3
      mode     = "delay"
    }

    network {
      dns { servers = ["1.1.1.1", "1.0.0.1"] }
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
        interval = "10s"
        timeout  = "5s"

        success_before_passing   = 1
        failures_before_critical = 3
      }

    }

    service {
      name = "blocky-dns"
      port = "dns"

      tags = [
        "traefik.enable=true",
        "traefik.udp.routers.adguard-dns.entrypoints=dns-udp",
      ]

      check {
        name     = "blicky-dns"
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"

        success_before_passing   = 1
        failures_before_critical = 3
      }
    }

    task "dns" {
      driver = "docker"

      config {
        image       = "ghcr.io/0xerr0r/blocky"
        force_pull  = false
        volumes     = ["local/config.yml:/app/config.yml"]
        ports       = ["http", "dns"]
        dns_servers = ["1.1.1.1", "1.0.0.1"]
      }

      template {
        destination = "local/config.yml"
        change_mode = "restart"
        data        = <<EOF
minTlsServeVersion: 1.3
upstreams:
  strategy: strict
  groups:
    default:
      - https://security.cloudflare-dns.com/dns-query
      - https://extended.dns.mullvad.net/dns-query
bootstrapDns:
  - https://1.1.1.2/dns-query
ports:
  dns: {{ env `NOMAD_PORT_dns` }}
  http: {{ env `NOMAD_PORT_http` }}
blocking:
  loading:
    strategy: fast
    concurrency: 2
    refreshPeriod: 12h
    downloads:
      cooldown: 30s
      timeout: 1m
      attempts: 5
  blockType: nxDomain
  blockTTL: 60s
  whiteLists:
    tracking:
      - /icloud.com/
      - /apple.com/
  blackLists:
    suspicious:
      - https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
      - https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt
      - https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts
      - https://v.firebog.net/hosts/static/w3kbl.txt
      - https://raw.githubusercontent.com/matomo-org/referrer-spam-blacklist/master/spammers.txt
      - https://v.firebog.net/hosts/neohostsbasic.txt
    ads:
      - https://adaway.org/hosts.txt
      - https://v.firebog.net/hosts/Admiral.txt
      - https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt
      - https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
      - https://v.firebog.net/hosts/Easylist.txt
      - https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext
      - https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts
      - https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts
      - https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts
      - https://v.firebog.net/hosts/Easyprivacy.txt
      - https://v.firebog.net/hosts/Prigent-Ads.txt
    tracking:
      - https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts
      - https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt
      - https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt
      - https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt
      - https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/android-tracking.txt
      - https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt
      - https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/AmazonFireTV.txt
    malware:
      - https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt
      - https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt
      - https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt
      - https://phishing.army/download/phishing_army_blocklist_extended.txt
      - https://v.firebog.net/hosts/RPiList-Malware.txt
      - https://v.firebog.net/hosts/RPiList-Phishing.txt
  clientGroupsBlock:
    default:
      - ads
      - suspicious
      - tracking
      - malware
caching:
  minTime: 5m
  maxTime: 12h
  maxItemsCount: 2048
  cacheTimeNegative: 1m
  prefetching: true
  prefetchThreshold: 5
  prefetchMaxItemsCount: 512
{{ range service "postgres" }}
queryLog:
  type: postgresql
  logRetentionDays: 90
  target: postgres://{{ with nomadVar "nomad/jobs/blocky" }}{{ .POSTGRES_USERNAME }}:{{ .POSTGRES_PASSWORD }}{{ end }}@{{ .Address }}:{{ .Port }}/blocky?sslmode=disable
{{ end }}
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
  privacy: true
connectIPVersion: v4
filtering:
  queryTypes:
    - AAAA
EOF
      }


      resources {
        cpu    = 1000
        memory = 512
      }
    }

    constraint {
      operator = "distinct_hosts"
      value    = "true"
    }

    affinity {
      attribute = "${node.class}"
      value     = "compute"
      weight    = 90
    }
  }

  # Manual updates 
  update {
    max_parallel     = 1
    canary           = 1
    min_healthy_time = "1m"
    healthy_deadline = "2m"
    auto_revert      = true
    auto_promote     = true
  }

  # Migrations during node draining
  migrate {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "1m"
    healthy_deadline = "2m"
  }
}



