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

# target start block seconds ago
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

demo-prepare-local:
	@echo "🔢 Finding block number and timestamps..."
	@bash ./scripts/pipeline-window.sh $(SECONDS_AGO)
	@bash ./scripts/determine-dmrkt-address.sh


# ───────────────────────────────────────────────
#   START
# ───────────────────────────────────────────────

demo-up:
	@PHRASE=$$(jq -r .mnemonic $(MNEMONIC_JSON)) && \
	cp .env .env.runtime && \
	echo "PHRASE=$$PHRASE" >> .env.runtime && \
	docker compose --env-file .env.runtime up

# ───────────────────────────────────────────────
#   RESET
# ───────────────────────────────────────────────

demo-reset:
	docker compose down --volumes --remove-orphans