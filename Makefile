include .env
export

PROJECT_ROOT := $(shell pwd)
export PROJECT_ROOT

# pipeline window
EPOCH_COUNT ?= 4
EPOCH_SIZE ?= 604800 # seconds (7 days)

# target start block seconds ago
SECONDS_AGO = $(shell expr $(EPOCH_COUNT) \* $(EPOCH_SIZE))

# ───────────────────────────────────────────────
#   START
# ───────────────────────────────────────────────

demo-prepare: 
	@echo "🔢 Finding block number and timestamps..."
	@node ./scripts/pipeline-window.js $(SECONDS_AGO)

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