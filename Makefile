# NOTE: include .env snapshots vars at parse time; demo-up reloads .env.runtime

# these will get stale when setup scripts in demo-prepare runs
# demo-up must set the vars to these fresh values before running docker compose
# done by: set -a && . ./.env.runtime && set +a
include .env
export

PROJECT_ROOT  := $(shell pwd)
TOML          := $(PROJECT_ROOT)/config/sim/pipeline.toml
MNEMONIC_JSON := $(PROJECT_ROOT)/config/sim/mnemonic.example.json
RPC_URL       := $(SNAP_RPC_URL)/$(API_KEY)
PHRASE        := $(shell jq -r .mnemonic $(MNEMONIC_JSON))

export PROJECT_ROOT TOML MNEMONIC_JSON RPC_URL PHRASE

# pipeline window
EPOCH_COUNT ?= 4
EPOCH_SIZE ?= 604800 # seconds (7 days)

SECONDS_AGO = $(shell expr $(EPOCH_COUNT) \* $(EPOCH_SIZE))

# ───────────────────────────────────────────────
#   ENTRYPOINT
# ───────────────────────────────────────────────

dapp: demo-prepare demo-up

# ───────────────────────────────────────────────
#   PREP
# ───────────────────────────────────────────────

demo-prepare:
	@echo "🔢 Finding block number and timestamps..."
	@docker compose --profile setup run --rm setup

# runs setup locally instead of in container (requires foundry)
demo-prepare-local:
	@echo "🔢 Finding block number and timestamps..."
	@bash ./scripts/pipeline-window.sh $(SECONDS_AGO)
	@bash ./scripts/determine-dmrkt-address.sh


# ───────────────────────────────────────────────
#   START
# ───────────────────────────────────────────────

# reload .env.runtime so compose sees values written by demo-prepare, not the stale snapshot
demo-up:
	@PHRASE=$$(jq -r .mnemonic $(MNEMONIC_JSON)) && \
	cp .env .env.runtime && \
	echo "PHRASE=\"$$PHRASE\"" >> .env.runtime
	@set -a && . ./.env.runtime && set +a && \
	docker compose up

# ───────────────────────────────────────────────
#   RESET
# ───────────────────────────────────────────────

demo-reset:
	docker compose down --volumes --remove-orphans
