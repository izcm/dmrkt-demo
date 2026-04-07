include .env
export

PROJECT_ROOT  := $(shell pwd)
TOML          := $(PROJECT_ROOT)/config/sim/pipeline.toml
MNEMONIC_JSON := $(PROJECT_ROOT)/config/sim/mnemonic.example.json
RPC_URL       := $(SNAP_RPC_URL)/$(API_KEY)

export PROJECT_ROOT TOML MNEMONIC_JSON RPC_URL

# pipeline window
EPOCH_COUNT ?= 4
EPOCH_SIZE ?= 604800 # seconds (7 days)

# target start block seconds ago
SECONDS_AGO = $(shell expr $(EPOCH_COUNT) \* $(EPOCH_SIZE))


# ───────────────────────────────────────────────
#   PREP
# ───────────────────────────────────────────────

demo-prepare:
	@echo "🔢 Finding block number and timestamps..."
	@bash ./scripts/pipeline-window.sh $(SECONDS_AGO)
	@bash ./scripts/determine-dmrkt-address.sh

# ───────────────────────────────────────────────
#   START
# ───────────────────────────────────────────────

demo-up:
	@echo "🔑 Loading mnemonic..."
	@export PHRASE=$$(jq -r .mnemonic $(MNEMONIC_JSON)) && \
	docker compose up


# ───────────────────────────────────────────────
#   RESET
# ───────────────────────────────────────────────

demo-reset: remove-containers remove-volumes

# TODO: make these only remove the docker containers+ 
# volumes connected to the repo

remove-containers:
	docker rm $(shell docker ps -a -q)

remove-volumes:
	docker volume prune -f