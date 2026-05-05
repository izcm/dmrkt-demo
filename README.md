# dmrkt playground

On my journey to learn web3, having written an tested some contracts, I wanted to make a realistic marketplace demo.

The first obstacle was how to populate the demo with data, as it wasn't as straightforward as seeding a regular DB.

While learning foundry scripting, I realized I could control the economy 😈 — locally.
So instead of seeding data, I simulated it.

The foundry pipeline is the heart of this demo, and likely the more exciting thing to check out if your focus is web3.

- [How it works](#how-it-works)
- [Getting started](#getting-started)
- [Reset](#reset)
- [Troubleshooting](#troubleshooting)
- [What to improve](#what-to-improve)

---

## How it works

A fully populated NFT marketplace running at `localhost:3000` — with historical listings, bids, and sales already in the database when the frontend loads. No blank-slate local chain; the demo bootstraps ~28 days of on-chain activity before you open a browser.

### Services

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

### Pipeline

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

**READMEs for the other repos are not yet written**, but will be within the next week or so.

---

## Getting started

### Prerequisites

- Docker + Docker Compose
- An [Alchemy](https://www.alchemy.com/) API key (mainnet RPC access)

### Run

```bash
# 1. Add your Alchemy API key to .env
#    API_KEY=your_key_here

# 2. Start everything
make dapp
```

`make dapp` runs two steps:

- **prepare** — queries mainnet to compute the fork block and timestamps, derives the marketplace contract address deterministically, and writes both into config and env files; runs inside a container so no local tooling is needed
- **up** — starts all services via Docker Compose in the correct order

The first run takes a few minutes while Anvil syncs the fork and sim replays events. The frontend is ready when `localhost:3000` loads with marketplace data, with the initial page showing pipeline progress.

This would be a great time for a coffee break ☕

> If you have [Foundry](https://book.getfoundry.sh/) installed locally, you can run `make demo-prepare-local && make demo-up` instead to skip the setup container.

### Connect your wallet

All participants in any marketplace activity are derived from the same mnemonic

---

## Reset

```bash
make demo-reset
```

Tears down all containers and volumes. Safe to re-run `make dapp` after.

## Troubleshooting

**`RPC_URL not set`** — check that `API_KEY` is set in `.env`

**Contract address errors** — re-run `make demo-prepare` to rederive the address from the current fork block

**Indexer not syncing** — `FORK_START_BLOCK` mismatch; re-run `make demo-prepare`. Should not happen if you're using `make dapp` as entrypoint.

---

## What to improve

As the demo moved into a gaming theme, where each NFT represents a game asset, I realized ERC1155 would be a better fit than ERC721.

To see why, after spinning up dmrkt, try the following search in the `explore` tab:

```
trait.type=sword trait.rarity=common trait.color=blood_red trait.element=none
```

This returns ~30 identical-looking swords. In the current ERC721 collection, each of these is a separate NFT (`tokenId`), meaning every sword is treated as a unique asset, _a non-fungible token_. This works, but doesn’t fit this use case well.

With ERC1155, instead of one `tokenId` per sword, a single id could represent the item (e.g. "Common Blood Red Sword"), with balances tracked per user; `balanceOf(owner, id)`.

This way, a user’s swords are just their balance of that item, rather than many separate tokens, making them _fungible tokens_.

The marketplace contract would also need to be extended to support ERC1155-based orders.
