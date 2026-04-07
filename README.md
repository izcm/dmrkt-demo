# From forking hell, to forking great!

**_Breathing life into web3 demos_**

> An _izcm_ demo showcasing an end-to-end marketplace that warps time on a local Anvil fork to generate realistic and deterministic historical on-chain data.  
> Great for devs looking to level up their dev environments — and for those who want an interactive introduction to full-stack Web3 development.

This repo builds all the necessary parts to run dmrkt, a minimal NFT marketplace, on your local machine 🚀👾

In addition to starting all services and deploying contracts, the demo also includes a pipeline that bootstraps our Anvil fork with historical data, truly breathing life into dmrkt!

## Services

- Anvil (local chain)
- [Marketplace Contracts & Foundry Scripts][contracts]
- [Backend API / Indexer][indexer]
- [Frontend][frontend]

[contracts]: https://github.com/izcm/dmrkt-contracts
[indexer]: https://github.com/izcm/dmrkt-indexer
[frontend]: https://github.com/izcm/dmrkt-frontend

## Flow

Anvil → Contracts → Events → Indexer → DB → Socket → UI
Anvil &rarr; Contracts &rarr; Events &rarr; Indexer &rarr; DB &rarr; Socket &rarr; UI

Run with:
docker compose up --build

```
foundry scripts
        │
        ▼
   anvil fork
        │
        ▼
   contracts emit events
        │
        ▼
     indexer
        │
        ▼
      API
        │
        ▼
     frontend
```
