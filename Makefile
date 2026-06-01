# NOTE: include .env static vars at parse time; demo-up loads .env.runtime

include .env
export

# the user that runs make owns out/ + config/
UID := $(shell id -u)
export UID


PROJECT_ROOT  := $(shell pwd)
TOML          := $(PROJECT_ROOT)/config/sim/pipeline.toml
MNEMONIC_JSON := $(PROJECT_ROOT)/config/sim/mnemonic.example.json

# user can configure APP_HOST in .env – defaults to localhost
APP_HOST ?= localhost

export PROJECT_ROOT TOML MNEMONIC_JSON APP_HOST

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

# compute context
demo-prepare: ensure-dirs
	@bash ./scripts/ensure-statics.sh
	@cp .env .env.runtime
	@echo "🐳 Pulling setup image..."
	@docker compose pull setup
	@echo "🔢 Finding block number and timestamps..."
	@docker compose --profile setup run --rm setup

# run setup locally instead of in container (requires foundry)
demo-prepare-local: ensure-dirs
	@bash ./scripts/ensure-statics.sh
	@cp .env .env.runtime
	@echo "🔢 Finding block number and timestamps..."
	@bash ./scripts/pipeline-window.sh $(SECONDS_AGO)
	@bash ./scripts/determine-dmrkt-address.sh

# NOTE: touch/mkdir so the demo runner owns the files, not root via docker
# chmod 777 allows container user (UID 1000) to write into mounted dirs on mac
ensure-dirs:
	@mkdir -p config/sim
	@mkdir -p out/broadcast
	@touch out/sim.log
	@touch chains.json
	@chmod -R 777 config/sim out/broadcast out/sim.log

# ───────────────────────────────────────────────
#   START
# ───────────────────────────────────────────────

check-ports:
# todo: add 3000
	@for port in 8545 5000 5001; do \
			if ss -l sport = :$$port 2>/dev/null | grep -q LISTEN; then \
			echo "❌ Port $$port is in use. Try 'make demo-reset'. If problem persists: kill $$(lsof -i :$$port -t)"; \
			exit 1; \
		fi \
	done

# reload .env.runtime so compose sees values written by demo-prepare
demo-up: check-ports
	@set -a && . ./.env.runtime && set +a && \
	docker compose up --build

# ───────────────────────────────────────────────
#   RESET
# ───────────────────────────────────────────────

demo-reset:
	docker compose down --volumes --remove-orphans
