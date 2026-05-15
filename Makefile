# NOTE: include .env snapshots vars at parse time; demo-up reloads .env.runtime

# these will get stale when setup scripts in demo-prepare runs
# demo-up must set the vars to these fresh values before running docker compose
# done by: set -a && . ./.env.runtime && set +a
include .env
export

PROJECT_ROOT  := $(shell pwd)
TOML          := $(PROJECT_ROOT)/config/sim/pipeline.toml
MNEMONIC_JSON := $(PROJECT_ROOT)/config/sim/mnemonic.example.json
PHRASE        := $(shell jq -r .mnemonic $(MNEMONIC_JSON))

export PROJECT_ROOT TOML MNEMONIC_JSON PHRASE

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

# ensure static addresses and key phrase / mnemonic
ensure-sim-config:
	bash ./scripts/ensure-mnemonic.sh
	bash ./scripts/ensure-statics.sh

# compute context
demo-prepare: ensure-sim-config
	@cp .env .env.runtime
	@echo "🔢 Finding block number and timestamps..."
	docker compose --profile setup run --rm setup

# run setup locally instead of in container (requires foundry)
demo-prepare-local: ensure-sim-config
	@echo "🔢 Finding block number and timestamps..."
	@bash ./scripts/pipeline-window.sh $(SECONDS_AGO)
	@bash ./scripts/determine-dmrkt-address.sh


# ───────────────────────────────────────────────
#   START
# ───────────────────────────────────────────────

check-ports:
	@for port in 8545 3000 5000 5001; do \
		if lsof -i :$$port -t >/dev/null 2>&1; then \
			echo "❌ Port $$port is in use. Try 'make demo-reset'. If problem persists: kill $$(lsof -i :$$port -t)"; \
			exit 1; \
		fi \
	done

# reload .env.runtime so compose sees values written by demo-prepare, not the stale snapshot
demo-up: check-ports
	@PHRASE=$$(jq -r .mnemonic $(MNEMONIC_JSON)) && \
	echo "PHRASE=\"$$PHRASE\"" >> .env.runtime
	@set -a && . ./.env.runtime && set +a && \
	docker compose up

# ───────────────────────────────────────────────
#   RESET
# ───────────────────────────────────────────────

demo-reset:
	docker compose down --volumes --remove-orphans
