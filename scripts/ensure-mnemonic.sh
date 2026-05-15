#!/bin/bash
set -e

FILE="config/sim/mnemonic.example.json"
PHRASE=$(grep -o '"mnemonic":"[^"]*"' "$FILE" 2>/dev/null | cut -d'"' -f4)

if cast wallet address --mnemonic "$PHRASE" > /dev/null 2>&1; then
    exit 0
fi

PHRASE=$(cast wallet new-mnemonic | grep -A1 "Phrase" | tail -1)
cat > "$FILE" <<EOF
{
  "chainId": 31337,
  "note": "Deterministic dev-only private keys for Anvil. DO NOT USE ON REAL CHAINS.",
  "mnemonic": "$PHRASE"
}
EOF
