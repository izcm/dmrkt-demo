#!/usr/bin/env bash
set -euo pipefail

# Computes fork block + timestamps, writes them into TOML ([31337.uint])
# and syncs FORK_START_BLOCK into .env

# === config ===

: "${RPC_URL:?🚨 RPC_URL not set}"
: "${TOML:?🚨 TOML not set}"

SECONDS_AGO=${1:?🚨 pass seconds ago}
PIPELINE_END_TS=${2:-$(date +%s)}

# === get timestamps ===

LATEST_TS=$(cast block latest --json --rpc-url "$RPC_URL" | jq -r .timestamp)

TARGET_TS=$((LATEST_TS - SECONDS_AGO))

FORK_START_BLOCK=$(cast find-block "$TARGET_TS" --rpc-url "$RPC_URL")

BLOCK_JSON=$(cast block "$FORK_START_BLOCK" --json --rpc-url "$RPC_URL")
PIPELINE_START_TS=$(echo "$BLOCK_JSON" | jq -r .timestamp)

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

# === write to .env files ===

for ENV_FILE in .env env.example/indexer.env; do
    if [ -f "$ENV_FILE" ] && grep -q '^FORK_START_BLOCK=' "$ENV_FILE"; then
        TMP_ENV=$(mktemp)
        sed "s/^FORK_START_BLOCK=.*/FORK_START_BLOCK=$FORK_START_BLOCK/" "$ENV_FILE" > "$TMP_ENV"
        cp "$TMP_ENV" "$ENV_FILE" && rm -f "$TMP_ENV"
    else
        echo "FORK_START_BLOCK=$FORK_START_BLOCK" >> "$ENV_FILE"
    fi
    echo "Wrote $ENV_FILE"
done

# === logs ===

sep() { echo "========================================"; }

echo
sep
echo "✔ Complete!"
sep
echo
echo " Fork target block: $FORK_START_BLOCK"
echo
echo "⏰ Timestamps:"
echo "  start: $PIPELINE_START_TS"
echo "  end:   $PIPELINE_END_TS"
echo
sep
echo