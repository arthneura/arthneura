#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKET="$ROOT/../arthneura-market"
test -d "$MARKET" || { echo "missing sibling arthneura-market"; exit 1; }
echo "FIGHT path: bad csv row -> refund or counter"
echo "compose must already be up"
"$MARKET/scripts/market-csv-fail.sh"
echo "---"
"$MARKET/scripts/market-csv-counter.sh"
