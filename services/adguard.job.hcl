job "adguard" {
  type = "service"
  priority = 90

  constraint {
    attribute = "${node.class}"
    value     = "compute"
  }

  group "home" {
    restart {
      delay    = "5s"
      interval = "30s"
      attempts = 3
      mode     = "delay"
    }

    network {
      port "http" {
        # Note that after the initial config, 
        # we need to set the port to 3000
        to = 3000
      }

      port "dns" {
        to = 53
      }
    }

    volume "work" {
      type            = "csi"
      source          = "adguard-work"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    volume "config" {
      type            = "csi"
      source          = "adguard-config"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
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
    }

    service {
      name = "adguard-dns"
      port = "dns"

      tags = [
        "traefik.enable=true",
        "traefik.udp.routers.adguard-dns.entrypoints=dns-udp",
      ]
    }

    task "resolver" {
      driver = "docker"

      config {
        image = "adguard/adguardhome"
        volumes = ["local:/opt/adguardhome/conf"]
        ports = ["http", "dns"]
      }

      volume_mount {
        volume      = "work"
        destination = "/opt/adguardhome/work"
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
block_auth_min: 15
http_proxy: ""
language: ""
theme: auto
dns:
  bind_hosts:
    - 0.0.0.0
  port: 53
  anonymize_client_ip: false
  ratelimit: 20
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
  cache_optimistic: true
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
  serve_http3: false
  use_http3_upstreams: false
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
  interval: 720h
  size_memory:1000
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
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt
    name: AdAway Default Blocklist
    id: 2
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_44.txt
    name: HaGeZi's Threat Intelligence Feeds
    id: 1694430533
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_12.txt
    name: Dandelion Sprout's Anti-Malware List
    id: 1694430534
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_18.txt
    name: Phishing Army
    id: 1694430535
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt
    name: Phishing URL Blocklist (PhishTank and OpenPhish)
    id: 1694430536
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_10.txt
    name: Scam Blocklist by DurableNapkin
    id: 1694430537
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_8.txt
    name: NoCoin Filter List
    id: 1694430538
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_23.txt
    name: WindowsSpyBlocker - Hosts spy rules
    id: 1694430539
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_31.txt
    name: Stalkerware Indicators List
    id: 1694430540
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt
    name: The Big List of Hacked Malware Web Sites
    id: 1694430541
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_34.txt
    name: HaGeZi Multi NORMAL
    id: 1694430542
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_42.txt
    name: ShadowWhisperer's Malware List
    id: 1694430543
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt
    name: Malicious URL Blocklist (URLHaus)
    id: 1694430544
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_32.txt
    name: The NoTracking blocklist
    id: 1694430545
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_38.txt
    name: 1Hosts (mini)
    id: 1694452742
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_47.txt
    name: HaGeZi's Gambling Blocklist
    id: 1694452743
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_7.txt
    name: Perflyst and Dandelion Sprout's Smart-TV Blocklist
    id: 1694452744
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_27.txt
    name: OISD Blocklist Big
    id: 1694452745
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_6.txt
    name: Dandelion Sprout's Game Console Adblock List
    id: 1694452746
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_5.txt
    name: OISD Blocklist Small
    id: 1694452747
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_4.txt
    name: Dan Pollock's List
    id: 1694544263
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_24.txt
    name: 1Hosts (Lite)
    id: 1694544264
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_33.txt
    name: Steven Black's List
    id: 1694544265
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_3.txt
    name: Peter Lowe's Blocklist
    id: 1694544266
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_46.txt
    name: HaGeZi's Anti-Piracy Blocklist
    id: 1694544267
  - enabled: true
    url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_17.txt
    name: "SWE: Frellwit's Swedish Hosts File"
    id: 1694544268
  - enabled: true
    url: https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
    name: disconnect.me
    id: 1695046789
  - enabled: true
    url: https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/MobileFilter/sections/specific_app.txt
    name: AdguardTeam Mobile Ad
    id: 1695046790
  - enabled: true
    url: https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Formats/GoodbyeAds-AdBlock-Filter.txt
    name: Goodbye Ads - Generic
    id: 1695046791
  - enabled: true
    url: https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Formats/GoodbyeAds-YouTube-AdBlock-Filter.txt
    name: Goodbye Ads - Youtube
    id: 1695046792
  - enabled: true
    url: https://raw.githubusercontent.com/DandelionSprout/adfilt/master/NorwegianExperimentalList%20alternate%20versions/NordicFiltersAdGuardHome.txt
    name: Nordic filter
    id: 1695281457
  - enabled: true
    url: https://raw.githubusercontent.com/AdguardTeam/cname-trackers/master/data/combined_disguised_trackers.txt
    name: AdGuard CNAME disguised trackers list
    id: 1695281458
  - enabled: true
    url: https://raw.githubusercontent.com/nextdns/native-tracking-domains/main/domains/windows
    name: NextDNS - Windows Privacy
    id: 1695281459
  - enabled: true
    url: https://raw.githubusercontent.com/nextdns/native-tracking-domains/main/domains/samsung
    name: NextDNS - Samsung
    id: 1695281460
  - enabled: true
    url: https://easylist-downloads.adblockplus.org/antiadblockfilters.txt
    name: Adblock Warning Removal List
    id: 1695281461
  - enabled: true
    url: https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt
    name: Threat-Intel - Security
    id: 1695281462
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
        cpu    = 2000
        memory = 2048
      }
    }
  }

  # Manual updates 
  update {
    max_parallel     = 1
    canary           = 1
    min_healthy_time = "30s"
    healthy_deadline = "1m"
    auto_revert      = true
    auto_promote     = true
  }

  # Migrations during node draining
  migrate {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "30s"
    healthy_deadline = "1m"
  }
}



