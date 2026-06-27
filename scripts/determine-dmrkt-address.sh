#!/usr/bin/env bash
set -euo pipefail

# 1. Derive private key at mnemonic index 0 — corresponding address is the deployer
# 2. Read deployer's nonce at the fork block
# 3. Compute marketplace contract address from deployer address + nonce

ENV_RUNTIME="${ENV_RUNTIME:-.env.runtime}"

# read mnemonic
PHRASE="$PARTICIPANT_MNEMONIC"
if [ -z "$PHRASE" ]; then
    echo "Error: PARTICIPANT_MNEMONIC not set"
    exit 1
fi

# derive deployer key + address
DEPLOYER_PK=$(cast wallet private-key --mnemonic "$PHRASE" --mnemonic-index 0)
DEPLOYER_ADDR=$(cast wallet address "$DEPLOYER_PK")

# read fork start block from pipeline config
AT_BLOCK=$(grep '^\s*fork_start_block\s*=' "$TOML" | awk -F'=' '{print $2}' | tr -d ' \t\r\n')

# get deployer nonce at fork block
NONCE=$(cast nonce "$DEPLOYER_ADDR" \
  --block "$AT_BLOCK" \
  --rpc-url "$MAINNET_RPC")

# compute marketplace address from deployer address + nonce
MARKETPLACE_ADDR=$(cast compute-address "$DEPLOYER_ADDR" --nonce "$NONCE" | awk '{print $NF}')

echo "🔐 deployer    $DEPLOYER_ADDR  (nonce $NONCE at block $AT_BLOCK)"
echo "🏗️  marketplace $MARKETPLACE_ADDR"
echo ""

# write or replace marketplace_addr env.runtime
if grep -q "^MARKETPLACE_ADDR=" "$ENV_RUNTIME"; then
    sed -i "s|^MARKETPLACE_ADDR=.*|MARKETPLACE_ADDR=${MARKETPLACE_ADDR}|" "$ENV_RUNTIME"
else
    echo "MARKETPLACE_ADDR=${MARKETPLACE_ADDR}" >> "$ENV_RUNTIME"
fi

# write to chains.json
cat > "./chains.json" << EOF
[
  {
    "rpcUrl": "http://anvil:8545",
    "marketplaceAddr": "$MARKETPLACE_ADDR"
  }
]

EOF
