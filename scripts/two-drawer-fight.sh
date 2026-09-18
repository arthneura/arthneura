#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CORE="${ARTHNEURA_CORE:-$ROOT/../arthneura-core}"
ALICE_DIR="${ALICE_DIR:-$HOME/agents/alice}"
BOB_DIR="${BOB_DIR:-$HOME/agents/bob}"
CHAIN_WS="${CHAIN_WS:-ws://127.0.0.1:9944}"
PASS="${KEYSTORE_PASS:-dev-passphrase}"
BAD_HASH="0000000000000000000000000000000000000000000000000000000000000001"

test -d "$CORE" || { echo "ERROR missing $CORE"; exit 1; }
curl -sf http://127.0.0.1:8080/health >/dev/null || { echo "ERROR api down"; exit 1; }

mkdir -p "$ALICE_DIR" "$BOB_DIR"
export CHAIN_WS KEYSTORE_PASS="$PASS"

echo "=== 1. alice ==="
ALICE_OUT="$(
  cd "$CORE"
  SIGNER=alice KEY_LABEL=alice LABEL=alice-agent KEYSTORE_DIR="$ALICE_DIR" \
    cargo run -q -p offchain-agent-registry
)"
echo "$ALICE_OUT"
PROVIDER_DID="$(echo "$ALICE_OUT" | sed -n 's/^DID=//p' | tail -n 1)"

echo "=== 2. bob ==="
BOB_OUT="$(
  cd "$CORE"
  SIGNER=bob KEY_LABEL=bob LABEL=bob-agent KEYSTORE_DIR="$BOB_DIR" \
    cargo run -q -p offchain-agent-registry
)"
echo "$BOB_OUT"
CONSUMER_DID="$(echo "$BOB_OUT" | sed -n 's/^DID=//p' | tail -n 1)"
[ -n "$PROVIDER_DID" ] && [ -n "$CONSUMER_DID" ] || { echo "ERROR missing DID"; exit 1; }

echo "=== 3. register + lock ==="
export PROVIDER_DID CONSUMER_DID SCHEMA=csv.v1 PRICE=1000 CHUNK_MODE=rows
export PAYLOAD=$'company,domain,email\nAcme,acme.com,bad-email\nBeta,beta.com,hi@beta.com'
REG="$(
  cd "$CORE"
  ACTION=register SIGNER=alice cargo run -q -p offchain-vector-db
)"
echo "$REG"
COMMITMENT_ID="$(echo "$REG" | sed -n 's/^COMMITMENT_ID=//p' | tail -n 1)"
TOTAL_CHUNKS="$(echo "$REG" | sed -n 's/^TOTAL_CHUNKS=//p' | tail -n 1)"
cd "$CORE"
ACTION=acknowledge SIGNER=bob COMMITMENT_ID="$COMMITMENT_ID" CONSUMER_DID="$CONSUMER_DID" \
  cargo run -q -p offchain-vector-db

echo "=== 4. raise (bob, no alice counter) ==="
ACTION=raise SIGNER=bob COMMITMENT_ID="$COMMITMENT_ID" CONSUMER_DID="$CONSUMER_DID" \
  CHUNK_INDEX=1 TOTAL_CHUNKS="$TOTAL_CHUNKS" RECEIVED_CHUNK_HASH="$BAD_HASH" \
  cargo run -q -p offchain-vector-db

echo "=== 5. wait dispute window ==="
sleep 90

echo "=== 6. finalize ==="
ACTION=finalize SIGNER=bob COMMITMENT_ID="$COMMITMENT_ID" \
  cargo run -q -p offchain-vector-db

echo
echo "ALICE_DIR=$ALICE_DIR"
echo "BOB_DIR=$BOB_DIR"
echo "COMMITMENT_ID=$COMMITMENT_ID"
echo "RESULT=TWO_DRAWER_REFUNDED"
