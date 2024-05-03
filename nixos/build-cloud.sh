#! /usr/bin/env nix-shell
#! nix-shell -p jinja2-cli jq moreutils coreutils python311Packages.jinja2 python311Packages.jinja2-ansible-filters bash -i bash

OUTPUT_FILE=$(mktemp)

jinja2 cloud-init.tmpl \
  -D imports="common.nix,nomad.nix" \
  -D imports_content="$(cat common.nix | base64 -w0),$(cat nomad.nix | base64 -w0)" \
  -D nix_channel="nixos-23.11" \
  -D cloud_provider=hetzner\
| tee $OUTPUT_FILE

echo "File: $OUTPUT_FILE"

[ -f "$(command -v pbcopy)" ] && echo "Copied to clipboard" && cat $OUTPUT_FILE | pbcopy
