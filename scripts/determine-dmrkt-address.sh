#!/usr/bin/env bash
set -euo pipefail

# 1. Derive private key at mnemonic index 0 — corresponding address is the deployer
# 2. Read deployer's nonce at the fork block
# 3. Compute marketplace contract address from deployer address + nonce

sep() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

# read mnemonic
PHRASE=$(grep '"mnemonic"' config/sim/mnemonic.example.json | cut -d'"' -f4)
if [ -z "$PHRASE" ]; then
    echo "Error: no mnemonic found in config/sim/mnemonic.example.json"
    exit 1
fi

sep
echo "🔐 Deployer"
sep

# derive deployer key + address
DEPLOYER_PK=$(cast wallet private-key --mnemonic "$PHRASE" --mnemonic-index 0)
DEPLOYER_ADDR=$(cast wallet address "$DEPLOYER_PK")

echo "addr   → $DEPLOYER_ADDR"

echo ""
sep
echo "⛓️  Fork Context"
sep

# read fork start block from pipeline config
AT_BLOCK=$(grep '^\s*fork_start_block\s*=' "$TOML" | awk -F'=' '{print $2}' | tr -d ' \t\r\n')

echo "block  → $AT_BLOCK"

echo ""
sep
echo "🔢 Nonce @ fork"
sep

# get deployer nonce at fork block
NONCE=$(cast nonce "$DEPLOYER_ADDR" \
  --block "$AT_BLOCK" \
  --rpc-url "$MAINNET_RPC")

echo "nonce  → $NONCE"

echo ""
sep
echo "🏗️  Derived Contract"
sep

# compute marketplace address from deployer address + nonce
MARKETPLACE_ADDR=$(cast compute-address "$DEPLOYER_ADDR" --nonce "$NONCE" | awk '{print $NF}')

echo "addr   → $MARKETPLACE_ADDR"

# write to env
write_or_replace() {
    local file="$1" key="$2" value="$3"
    if [ -f "$file" ] && grep -q "^${key}=" "$file"; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$file"
    else
        echo "${key}=${value}" >> "$file"
    fi
}

write_or_replace .env.runtime MARKETPLACE_ADDR "$MARKETPLACE_ADDR"
echo "Wrote MARKETPLACE_ADDR → .env.runtime"

echo ""
echo "✅ done"
sep