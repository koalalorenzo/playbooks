#! /usr/bin/env nix-shell
#! nix-shell -p jinja2-cli jq moreutils coreutils python311Packages.jinja2 python311Packages.jinja2-ansible-filters bash -i bash

CLOUD_PROVIDER="hetzner"
NIX_CHANNEL="nixos-23.11"

IMPORT_FILES=(
  "common.nix"
)

EXTRA_FILES=(
  "consul.nix"
  "nomad.nix"
  "nomad-client.nix"
)

# Create the temporary output file
OUTPUT_FILE=$(mktemp)

base64_encode_files() {
  local files=("$@")
  local base64_encoded=()

  for file in "${files[@]}"; do
    base64_encoded+=("$(base64 -w0 "$file")")
  done

  # Join the base64-encoded strings with commas
  local encoded_str
  encoded_str=$(IFS=','; echo "${base64_encoded[*]}")

  echo "$encoded_str"
}

IMPORTS=$(IFS=','; echo "${IMPORT_FILES[*]}")
IMPORTS_CONTENT=$(base64_encode_files "${IMPORT_FILES[@]}")
EXTRA=$(IFS=','; echo "${EXTRA_FILES[*]}")
EXTRA_CONTENT=$(base64_encode_files "${EXTRA_FILES[@]}")

# Run jinja2 with the dynamically constructed variables
jinja2 cloud-init.tmpl \
  -D imports="$IMPORTS" \
  -D imports_content="$IMPORTS_CONTENT" \
  -D extra="$EXTRA" \
  -D extra_content="$EXTRA_CONTENT" \
  -D nix_channel="$NIX_CHANNEL" \
  -D cloud_provider="$CLOUD_PROVIDER" \
| tee $OUTPUT_FILE
echo "File: $OUTPUT_FILE"

[ -f "$(command -v pbcopy)" ] && echo "Copied to clipboard" && cat $OUTPUT_FILE | pbcopy
