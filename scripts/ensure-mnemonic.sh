#!/bin/bash
set -e

FILE="${MNEMONIC_JSON:-config/sim/mnemonic.example.json}"
PHRASE=$(grep -o '"mnemonic": "[^"]*"' "$FILE" 2>/dev/null | cut -d'"' -f4)

# found mnemonic?
if [ -n "$PHRASE" ]; then
    if cast wallet address --mnemonic "$PHRASE" > /dev/null 2>&1; then
        exit 0
    else
        echo "Error: the mnemonic found in $FILE is invalid." >&2
        echo "Delete the file and re-run to generate a new one." >&2
        exit 1
    fi
fi

PHRASE=$(cast wallet new-mnemonic | grep -A1 "Phrase" | tail -1)
cat > "$FILE" <<EOF
{
  "chainId": 31337,
  "note": "Deterministic dev-only private keys for Anvil. DO NOT USE ON REAL CHAINS.",
  "mnemonic": "$PHRASE"
}
EOF
