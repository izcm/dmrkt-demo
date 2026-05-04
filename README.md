# an NFT playground

This repo builds all the necessary parts to run dmrkt, a minimal NFT marketplace, on your local machine 👾

In addition to starting all services and deploying contracts, the demo also includes a pipeline that bootstraps our Anvil fork with historical data, bringing dmrkt to life!

## Why was this made?

As I got further on my journey to learn web3, having written an tested some contracts, I wanted to make a realistic marketplace demo.

The first obstacle was how I'd populate the demo with data, as it would obviously not be as straightforward as seeding a regular DB.

While experimenting with Foundry scripting, I realized I could control the economy 😈 — locally.
So instead of seeding data, I simulated it.

The foundry pipeline is the heart of this demo, and likely the more exciting to check out if your focus is web3.

## Future improvements

Halfway in the project, the demo moved into gaming theme, where each NFT represents a gaming object. I've realized ERC721 protocol doesn't really fit as cleanly as ERC1155 would. If you're foncused about why, then do a search for

## Services

| Service                                    | Port               | Role                                                        |
| ------------------------------------------ | ------------------ | ----------------------------------------------------------- |
| [anvil](https://book.getfoundry.sh/anvil/) | `8545`             | Local EVM fork of Ethereum mainnet                          |
| [sim][contracts]                           | —                  | Deploys contracts + runs Foundry scripts to generate events |
| [indexer][indexer]                         | `5000` / `5001 ws` | Backend API + WebSocket                                     |
| [frontend][frontend]                       | `3000`             | Marketplace UI                                              |
| mongo                                      | `27017`            | Data store                                                  |

[contracts]: https://github.com/izcm/dmrkt-contracts
[indexer]: https://github.com/izcm/dmrkt-indexer
[frontend]: https://github.com/izcm/dmrkt-frontend

## What You'll See

A fully populated NFT marketplace running at `localhost:3000` — with historical listings, bids, and sales already in the database when the frontend loads. No blank-slate local chain; the demo bootstraps ~28 days of on-chain activity before you open a browser.

## Prerequisites

- Docker + Docker Compose
- [Foundry](https://book.getfoundry.sh/) (`cast`)
- [`jq`](https://jqlang.org/)
- An [Alchemy](https://www.alchemy.com/) API key (mainnet RPC access)

## Run

```bash
# Install dependencies (once)
curl -L https://foundry.paradigm.xyz | bash && foundryup   # Foundry / cast
sudo apt install jq       # Debian/Ubuntu
brew install jq           # macOS

# 1. Add your Alchemy API key to .env
#    API_KEY=your_key_here

# 2. Start everything
make dapp
```

`make dapp` runs two steps:

- **prepare** — queries mainnet to compute the fork block and timestamps, derives the marketplace contract address deterministically, and writes both into config and env files
- **up** — starts all services via Docker Compose in the correct order

The first run takes a few minutes while Anvil syncs the fork and sim replays events. The frontend is ready when `localhost:3000` loads with marketplace data, with the initial page showing pipeline progress.

This would be a great time for a coffee break ☕

## How the Pipeline Works

```
mainnet RPC
     │  (fork at computed block)
     ▼
  anvil
     │  (deploy contracts)
     ▼
   sim  ──── Foundry scripts replay ~28 days of events
     │
     ▼
 indexer  ──── listens for events, writes to MongoDB
     │
     ▼
 frontend  ──── queries API + subscribes to WebSocket
```

The fork block is computed fresh each run so the historical window always ends near the current date.

> NB: READMEs for the other repos are not written yet, but will be within the next week or so.

## Reset

```bash
make demo-reset
```

Tears down all containers and volumes. Safe to re-run `make dapp` after.

## Troubleshooting

**`RPC_URL not set`** — check that `API_KEY` is set in `.env`

**Indexer not syncing** — `FORK_START_BLOCK` mismatch; re-run `make demo-prepare`

**Contract address errors** — re-run `make demo-prepare` to rederive the address from the current fork block
