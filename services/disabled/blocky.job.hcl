job "blocky" {
  type = "service"
  priority = 90

  constraint {
    attribute = "${node.class}"
    value     = "compute"
  }

  group "home" {
    restart {
      delay    = "5s"
      interval = "20s"
      attempts = 3
      mode     = "delay"
    }

    network {
      dns {
        servers = ["1.1.1.1", "1.0.0.1"]
      }

      port "http" {
        # Note that after the initial config, 
        # we need to set the port to 3000
        to = 3000
      }

      port "dns" {
        to = 53
      }
    }

    service {
      name = "adguard-http"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.adguard.entrypoints=web,websecure",
        "traefik.http.routers.adguard.rule=Host(`dns.elates.it`)",
        "traefik.http.routers.adguard.tls.certresolver=letsencrypt",
      ]

      check {
        name     = "adguard-http"
        type     = "http"
        path     = "/"
        interval = "60s"
        timeout  = "5s"

        success_before_passing   = 1
        failures_before_critical = 3
      }
      
    }

    service {
      name = "adguard-dns"
      port = "dns"

      tags = [
        "traefik.enable=true",
        "traefik.udp.routers.adguard-dns.entrypoints=dns-udp",
      ]

      check {
        name     = "adguard-dns"
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"

        success_before_passing   = 1
        failures_before_critical = 3
      }
    }

    task "resolver" {
      driver = "docker"

      config {
        image = "adguard/adguardhome"
        force_pull = false
        volumes = ["local:/opt/adguardhome/conf"]
        ports = ["http", "dns"]
        dns_servers = ["1.1.1.1","1.0.0.1"]
      }

      template {
        destination = "local/AdGuardHome.yaml"
        change_mode = "restart"
        data        = <<EOF
http:
  pprof:
    port: 6060
    enabled: false
  address: 0.0.0.0:3000
  session_ttl: 720h
{{ with nomadVar "nomad/jobs/adguard" }}
users:
  - name: {{ .USERNAME }}
    password: {{ .PASSWORD }}
{{ end }}
auth_attempts: 5
block_auth_min: 1
http_proxy: ""
language: ""
theme: auto
dns:
  bind_hosts:
    - 0.0.0.0
  port: 53
  anonymize_client_ip: false
  ratelimit: 60
  ratelimit_whitelist: []
  refuse_any: true
  upstream_dns:
    - https://dns.cloudflare.com/dns-query
    - https://dns.google/dns-query
    - https://doh.mullvad.net/dns-query
  upstream_dns_file: ""
  bootstrap_dns:
    - 1.1.1.1
    - 1.0.0.1
    - 2606:4700:4700::1111
    - 2606:4700:4700::1001
  fallback_dns:
    - 1.1.1.1
    - 1.0.0.1
  all_servers: false
  fastest_addr: true
  fastest_timeout: 1s
  allowed_clients: []
  disallowed_clients: []
  blocked_hosts:
    - stats.grafana.org
    - data.meethue.com
  trusted_proxies:
    - 127.0.0.0/8
    - ::1/128
  cache_size: 4194304
  cache_ttl_min: 60
  cache_ttl_max: 43200
  cache_optimistic: false
  bogus_nxdomain: []
  aaaa_disabled: true
  enable_dnssec: true
  edns_client_subnet:
    custom_ip: ""
    enabled: false
    use_custom: false
  max_goroutines: 300
  handle_ddr: true
  ipset: []
  ipset_file: ""
  bootstrap_prefer_ipv6: false
  upstream_timeout: 10s
  private_networks: []
  use_private_ptr_resolvers: true
  local_ptr_upstreams: []
  use_dns64: false
  dns64_prefixes: []
  serve_http3: true
  use_http3_upstreams: true
tls:
  enabled: false
  server_name: dns.elates.it
  force_https: false
  port_https: 443
  port_dns_over_tls: 853
  port_dns_over_quic: 853
  port_dnscrypt: 0
  dnscrypt_config_file: ""
  allow_unencrypted_doh: true
  certificate_chain: ""
  private_key: ""
  certificate_path: ""
  private_key_path: ""
  strict_sni_check: false
querylog:
  ignored: []
  interval: 168h
  size_memory: 1000
  enabled: true
  file_enabled: true
statistics:
  ignored: []
  interval: 168h
  enabled: true
filters:
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
    name: AdGuard DNS filter
    id: 1
  # Suspicious
  - enabled: true
    url: https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt
    name: KADHosts
    id: 3
  - enabled: true
    url: https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts
    name: FadeMind-hosts
    id: 4
  - enabled: true
    url: https://v.firebog.net/hosts/static/w3kbl.txt
    name: firebog.net-w3kbl
    id: 5
  - enabled: true
    url: https://raw.githubusercontent.com/matomo-org/referrer-spam-blacklist/master/spammers.txt
    name: Matomo spam list
    id: 6
  - enabled: true
    url: https://v.firebog.net/hosts/neohostsbasic.txt
    name: Firebog-NeoHostsBasic
    id: 7
  # Advertising
  - enabled: true
    url: https://adaway.org/hosts.txt
    id: 8
    name: adaway
  - enabled: true
    url: https://v.firebog.net/hosts/Admiral.txt
    id: 9 
    name: Admiral
  - enabled: true
    url: https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt
    id: 10
    name: anudeepND
  - enabled: true
    url: https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
    id: 11
    name: disconnect-simplead
  - enabled: true
    url: https://v.firebog.net/hosts/Easylist.txt
    id: 12
    name: Easylist
  - enabled: true
    url: https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext
    id: 13
    name: yoyo-ads
  - enabled: true
    url: https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts
    id: 14
    name: Fademind
  - enabled: true
    url: https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts
    id: 15
    name: bigdargon
  - enabled: true
    url: https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts
    id: 16
    name: jdlingyu
  # Tracking
  - enabled: true
    url: https://v.firebog.net/hosts/Easyprivacy.txt
    name: firebog-easyprivacy
    id: 17
  - enabled: true
    url: https://v.firebog.net/hosts/Prigent-Ads.txt
    name: firebog-prigent-ads
    id: 18
  - enabled: true
    url: https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts
    name: add-2o7Net
    id: 19
  - enabled: true
    url: https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt
    name: windows-spy
    id: 20
  - enabled: true
    url: https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt
    name: frogeye-trackers
    id: 21
  - enabled: true
    url: https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt
    name: ads-and-tracking
    id: 22
  - enabled: true
    url: https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/android-tracking.txt
    name: android-tracking
    id: 23
  - enabled: true
    url: https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt
    name: smart-tv
    id: 24
  - enabled: true
    url: https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/AmazonFireTV.txt
    name: amazon-fire-tv
    id: 25
  # Malicious
  - enabled: true
    url: https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt
    name: Dandelion-AntiMalware
    id: 26
  - enabled: true
    url: https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt
    name: Threat-Intel
    id: 27
  - enabled: true
    url: https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt
    name: disconnect-me-malware
    id: 28
  - enabled: true
    url: https://phishing.army/download/phishing_army_blocklist_extended.txt
    name: phisshing-army
    id: 29
  - enabled: true
    url: https://v.firebog.net/hosts/RPiList-Malware.txt
    name: Firebog-RPIList-Malware
    id: 30
  - enabled: true
    url: https://v.firebog.net/hosts/RPiList-Phishing.txt
    name: Firebog-RPIList-Phishing
    id: 31
whitelist_filters: []
user_rules:
  - "@@||icloud.com^"
  - "@@||apple.com^"
  - "@@||elates.it^"
  - "@@||setale.me^"
  - "@@||tailscale.io^"
  - "@@||tailscale.com^"
  - "@@||burro-great.ts.net^"
dhcp:
  enabled: false
  interface_name: ""
  local_domain_name: lan
  dhcpv4:
    gateway_ip: ""
    subnet_mask: ""
    range_start: ""
    range_end: ""
    lease_duration: 86400
    icmp_timeout_msec: 1000
    options: []
  dhcpv6:
    range_start: ""
    lease_duration: 86400
    ra_slaac_only: false
    ra_allow_slaac: false
filtering:
  blocking_ipv4: ""
  blocking_ipv6: ""
  blocked_services:
    schedule:
      time_zone: UTC
    ids:
      - wechat
      - weibo
      - tiktok
      - qq
  protection_disabled_until: null
  safe_search:
    enabled: false
    bing: true
    duckduckgo: false
    google: false
    pixabay: true
    yandex: true
    youtube: false
  blocking_mode: refused
  parental_block_host: family-block.dns.adguard.com
  safebrowsing_block_host: standard-block.dns.adguard.com
  rewrites:
    - domain: dns.setale.me
      answer: dns.elates.it
  safebrowsing_cache_size: 1048576
  safesearch_cache_size: 1048576
  parental_cache_size: 1048576
  cache_time: 30
  filters_update_interval: 24
  blocked_response_ttl: 10
  filtering_enabled: true
  parental_enabled: false
  safebrowsing_enabled: true
  protection_enabled: true
clients:
  runtime_sources:
    whois: true
    arp: true
    rdns: true
    dhcp: true
    hosts: true
  persistent: []
log:
  file: ""
  max_backups: 0
  max_size: 100
  max_age: 3
  compress: false
  local_time: false
  verbose: false
os:
  group: ""
  user: ""
  rlimit_nofile: 0
schema_version: 27
        EOF
      }


      resources {
        cpu    = 1000
        memory = 1024
      }
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



