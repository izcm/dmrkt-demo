#!/usr/bin/env bash
set -euo pipefail

# Computes fork block + timestamps, writes them into TOML ([31337.uint])
# and syncs FORK_START_BLOCK into .env.runtime

# === config ===

MNEMONIC_JSON="${MNEMONIC_JSON:-config/sim/mnemonic.example.json}"
ENV_RUNTIME="${ENV_RUNTIME:-.env.runtime}"

: "${MAINNET_RPC:?🚨 MAINNET_RPC not set}"
: "${TOML:?🚨 TOML not set}"

SECONDS_AGO=${1:?🚨 pass seconds ago}
PIPELINE_END_TS=${2:-$(date +%s)}

# === get timestamps ===

LATEST_TS=$(cast block latest -f timestamp --rpc-url "$MAINNET_RPC")

TARGET_TS=$((LATEST_TS - SECONDS_AGO))

FORK_START_BLOCK=$(cast find-block "$TARGET_TS" --rpc-url "$MAINNET_RPC")
PIPELINE_START_TS=$(cast block "$FORK_START_BLOCK" -f timestamp --rpc-url "$MAINNET_RPC")

# === write TOML ===

TMP_TOML=$(mktemp)

awk -v start="$PIPELINE_START_TS" \
    -v end="$PIPELINE_END_TS" \
    -v block="$FORK_START_BLOCK" \
    '
    BEGIN { in_section=0; written=0 }

    /^\[31337\.uint\]/ {
        print 
        print "pipeline_start_ts = " start
        print "pipeline_end_ts = " end
        print "fork_start_block = " block
        in_section=1
        written=1
        next
    }

    /^\[/ { in_section=0 }

    {
        if (in_section &&
            (index($0, "pipeline_start_ts") ||
            index($0, "pipeline_end_ts") ||
            index($0, "fork_start_block")))
            next

        print
    }

    END {
        if (!written) {
            print ""
            print "[31337.uint]"
            print "pipeline_start_ts = " start
            print "pipeline_end_ts = " end
            print "fork_start_block = " block
        }
    }
' "$TOML" > "$TMP_TOML"

cp "$TMP_TOML" "$TOML"

# === write to .env.runtime ===

if [ -f "$ENV_RUNTIME" ] && grep -q '^FORK_START_BLOCK=' "$ENV_RUNTIME"; then
    TMP_ENV=$(mktemp)
    sed "s/^FORK_START_BLOCK=.*/FORK_START_BLOCK=$FORK_START_BLOCK/" "$ENV_RUNTIME" > "$TMP_ENV"
    cp "$TMP_ENV" "$ENV_RUNTIME" && rm -f "$TMP_ENV"
else
    echo "FORK_START_BLOCK=$FORK_START_BLOCK" >> "$ENV_RUNTIME"
fi

echo "⛓️  fork block  $FORK_START_BLOCK  (ts $PIPELINE_START_TS → $PIPELINE_END_TS)"