#!/bin/bash
set -e

# ensures static mainnet addresses and rpc endpoint are available to the pipeline

TOML="config/sim/pipeline.toml"

if [ ! -f "$TOML" ]; then
cat > "$TOML" << EOF
[31337]
endpoint_url = "http://anvil:8545"

[31337.address]
weth = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
EOF
fi
