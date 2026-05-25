#!/bin/bash
set -e

# ensures a mnemonic is present in config/sim
#
# mnemonic present?
#   yes -> valid?
#            yes -> write to .env.runtime
#            no  -> print error
#   no  -> generate new mnemonic, write to config/sim + .env.runtime

MNEMONIC_JSON="${MNEMONIC_JSON:-config/sim/mnemonic.example.json}"
ENV_RUNTIME="${ENV_RUNTIME:-.env.runtime}"

sep() { echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; }

sep
echo "🔑 Mnemonic"
sep

PHRASE=""
if [ -f "$MNEMONIC_JSON" ]; then
    PHRASE=$(awk -F'"' '/mnemonic/{print $4}' "$MNEMONIC_JSON")
fi

write_phrase() {
    echo "PHRASE=\"$PHRASE\"" >> "$ENV_RUNTIME"
    echo "Wrote PHRASE → .env.runtime"
}

if [ -n "$PHRASE" ]; then
    echo "found   → $MNEMONIC_JSON"
    if cast wallet address --mnemonic "$PHRASE" > /dev/null 2>&1; then
        echo "valid   → yes"
        write_phrase
        echo ""
        echo "✅ done"
        sep
        exit 0
    else
        echo "Error: the mnemonic found in $MNEMONIC_JSON is invalid." >&2
        echo "Delete the MNEMONIC_JSON and re-run to generate a new one." >&2
        exit 1
    fi
fi

echo "found   → none, generating..."
PHRASE=$(cast wallet new-mnemonic | grep -A1 "Phrase" | tail -1)
cat > "$MNEMONIC_JSON" <<EOF
{
  "chainId": 31337,
  "note": "Deterministic dev-only private keys for Anvil. DO NOT USE ON REAL CHAINS.",
  "mnemonic": "$PHRASE"
}
EOF
echo "saved   → $MNEMONIC_JSON"
write_phrase

echo ""
echo "✅ done"
sep
