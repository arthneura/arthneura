#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKET="$ROOT/../arthneura-market"
CORE="$ROOT/../arthneura-core"
test -d "$MARKET" || { echo "missing sibling arthneura-market"; exit 1; }
test -d "$CORE" || { echo "missing sibling arthneura-core"; exit 1; }
echo "HAPPY path: good csv -> settle"
echo "compose must already be up (docker compose up --build)"
"$MARKET/scripts/market-csv-settle.sh"
