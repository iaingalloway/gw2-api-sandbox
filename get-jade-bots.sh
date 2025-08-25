#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/common.sh"
source "$SCRIPT_DIR/api-key.env"

SLOTS='["ServiceChip","PowerCore","SensoryArray"]'
CACHE_FILE="${SCRIPT_DIR}/items-cache.log"

[[ -f "$CACHE_FILE" ]] || touch "$CACHE_FILE"

printf 'Fetching characters\n' >&2
mapfile -t characters < <(gw2_api "characters" | jq -r '.[]')

character_bots_json=$(
{
  for character in "${characters[@]}"; do
    printf 'Fetching %s\n' "$character" >&2
    gw2_api "characters/$character/equipment" \
      | jq --arg name "$character" --argjson slots "$SLOTS" '{
          name: $name,
          equipment: [ (.equipment // [])[]
                        | select(.slot as $s | $slots | index($s)) ]
        }'
  done
} | jq -s .
)

item_ids_json=$(jq '[.[].equipment[]? | .id] | sort | unique' <<<"$character_bots_json")

missing_ids_json=$(
  jq -n \
    --argjson ids "$item_ids_json" \
    --slurpfile cache "$CACHE_FILE" '
      ($cache[0] // {}) as $c
    | ($ids // [])
    | map(tostring)
    | map(select($c[.] == null))
    '
)

if [[ $(jq 'length' <<<"$missing_ids_json") -gt 0 ]]; then
  printf 'Fetching %d new items\n' "$(jq -r 'length' <<<"$missing_ids_json")" >&2

  fetched_map_json=$(
    jq -r '.[]' <<<"$missing_ids_json" | while read -r id_s; do
      id="${id_s#\"}"; id="${id%\"}"
      printf 'Fetching %s\n' "$id" >&2
      gw2_api "items/$id" | jq '{(.id|tostring): .name}'
    done | jq -s 'add // {}'
  )

  tmp=$(mktemp)
  jq -n \
    --slurpfile cache "$CACHE_FILE" \
    --argjson new "$fetched_map_json" '
      ($cache[0] // {}) + $new
    ' > "$tmp"
  mv "$tmp" "$CACHE_FILE"
else
  printf 'No new items to fetch\n' >&2
fi

lookup_json=$(cat "$CACHE_FILE")

jq -n \
  --argjson chars "$character_bots_json" \
  --argjson lookup "$lookup_json" '
  def camel: (.[0:1] | ascii_downcase) + .[1:];

  $chars
  | map(
      . as $c
    | { name: $c.name
      , powerCore: null
      , sensoryArray: null
      , serviceChip: null
      }
    + (
        ($c.equipment // [])
        | map({ ( .slot | camel ): $lookup[(.id|tostring)] })
        | add // {}
      )
    )
  '
