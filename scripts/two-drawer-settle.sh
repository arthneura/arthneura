#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORE="${ARTHNEURA_CORE:-$ROOT/../arthneura-core}"
ALICE_DIR="${ALICE_DIR:-$HOME/agents/alice}"
BOB_DIR="${BOB_DIR:-$HOME/agents/bob}"
CHAIN_WS="${CHAIN_WS:-ws://127.0.0.1:9944}"
PASS="${KEYSTORE_PASS:-dev-passphrase}"

test -d "$CORE" || { echo "ERROR missing $CORE"; exit 1; }

echo "=== 0. health ==="
curl -sf http://127.0.0.1:8080/health >/dev/null || { echo "ERROR api down; docker compose up"; exit 1; }
code=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:9944 || true)
if [ "$code" = "000" ]; then
  echo "ERROR node not on 9944"
  exit 1
fi

mkdir -p "$ALICE_DIR" "$BOB_DIR"
export CHAIN_WS KEYSTORE_PASS="$PASS"

echo "=== 1. alice drawer ==="
ALICE_OUT="$(
  cd "$CORE"
  SIGNER=alice KEY_LABEL=alice LABEL=alice-agent KEYSTORE_DIR="$ALICE_DIR" \
    cargo run -q -p offchain-agent-registry
)"
echo "$ALICE_OUT"
PROVIDER_DID="$(echo "$ALICE_OUT" | sed -n 's/^DID=//p' | tail -n 1)"
[ -n "$PROVIDER_DID" ] || { echo "ERROR no alice DID"; exit 1; }

echo "=== 2. bob drawer ==="
BOB_OUT="$(
  cd "$CORE"
  SIGNER=bob KEY_LABEL=bob LABEL=bob-agent KEYSTORE_DIR="$BOB_DIR" \
    cargo run -q -p offchain-agent-registry
)"
echo "$BOB_OUT"
CONSUMER_DID="$(echo "$BOB_OUT" | sed -n 's/^DID=//p' | tail -n 1)"
[ -n "$CONSUMER_DID" ] || { echo "ERROR no bob DID"; exit 1; }

if [ "$PROVIDER_DID" = "$CONSUMER_DID" ]; then
  echo "ERROR alice and bob DID are the same"
  exit 1
fi

echo "=== 3. register ==="
export PROVIDER_DID CONSUMER_DID
export SCHEMA=csv.v1 PRICE=1000 CHUNK_MODE=rows
export PAYLOAD=$'company,domain,email\nAcme,acme.com,ops@acme.com\nBeta,beta.com,hi@beta.com'
REG="$(
  cd "$CORE"
  ACTION=register SIGNER=alice cargo run -q -p offchain-vector-db
)"
echo "$REG"
COMMITMENT_ID="$(echo "$REG" | sed -n 's/^COMMITMENT_ID=//p' | tail -n 1)"
MERKLE_ROOT="$(echo "$REG" | sed -n 's/^MERKLE_ROOT=//p' | tail -n 1)"
TOTAL_CHUNKS="$(echo "$REG" | sed -n 's/^TOTAL_CHUNKS=//p' | tail -n 1)"
[ -n "$COMMITMENT_ID" ] || { echo "ERROR register failed"; exit 1; }

echo "=== 4. ack ==="
cd "$CORE"
ACTION=acknowledge SIGNER=bob COMMITMENT_ID="$COMMITMENT_ID" CONSUMER_DID="$CONSUMER_DID" \
  cargo run -q -p offchain-vector-db

echo "=== 5. close ==="
ACTION=close SIGNER=bob COMMITMENT_ID="$COMMITMENT_ID" CONSUMER_DID="$CONSUMER_DID" \
  MERKLE_ROOT="$MERKLE_ROOT" TOTAL_CHUNKS="$TOTAL_CHUNKS" \
  cargo run -q -p offchain-vector-db

echo
echo "ALICE_DIR=$ALICE_DIR"
echo "BOB_DIR=$BOB_DIR"
echo "PROVIDER_DID=$PROVIDER_DID"
echo "CONSUMER_DID=$CONSUMER_DID"
echo "COMMITMENT_ID=$COMMITMENT_ID"
echo "RESULT=TWO_DRAWER_SETTLED"
