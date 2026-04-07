#!/usr/bin/env bash
set -euo pipefail

# Derives deployer (mnemonic index 0)
# Reads nonce at fork block
# Computes resulting marketplace contract address

sep() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

PHRASE=$(jq -r .mnemonic "$MNEMONIC_JSON")

sep
echo "🔐 Deployer"
sep

DEPLOYER_PK=$(cast wallet private-key --mnemonic "$PHRASE" --mnemonic-index 0)
DEPLOYER_ADDR=$(cast wallet address "$DEPLOYER_PK")

echo "addr   → $DEPLOYER_ADDR"

echo ""
sep
echo "⛓️  Fork Context"
sep

AT_BLOCK=$(grep '^\s*fork_start_block\s*=' "$TOML" | awk -F'=' '{print $2}' | tr -d ' \t\r\n')

echo "block  → $AT_BLOCK"

echo ""
sep
echo "🔢 Nonce @ fork"
sep

NONCE=$(cast nonce "$DEPLOYER_ADDR" \
  --block "$AT_BLOCK" \
  --rpc-url "$RPC_URL")

echo "nonce  → $NONCE"

echo ""
sep
echo "🏗️  Derived Contract"
sep

MARKETPLACE_ADDR=$(cast compute-address "$DEPLOYER_ADDR" --nonce "$NONCE" | awk '{print $NF}')

echo "addr   → $MARKETPLACE_ADDR"

echo ""
echo "✅ done"
sep