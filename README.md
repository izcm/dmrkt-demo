# dmrkt-demo

> This is an _izcm_ demo showcases indexing, event flow, and real-time UI updates.

## From forking hell, to forking great!

This repo builds all the necessary parts to run dmrkt, a minimal NFT marketplace, on your local machine 🚀👾

In addition to starting all services and deploying contracts, the demo also includes a pipeline that bootstraps the local anvil fork with historical data, truely breathing life into dmrkt!

Services:

- Anvil (local chain)
- [Marketplace Contracts & Foundry Scripts][contracts]
- [Backend API / Indexer][indexer]
- [Frontend][frontend]

[contracts]: https://github.com/izcm/dmrkt-engines
[indexer]: https://github.com/izcm/dmrkt-indexer
[frontend]: https://github.com/izcm/dmrkt-frontend

Anvil &rarr; Contracts &rarr; Events &rarr; Indexer &rarr; DB &rarr; Socket &rarr; UI

Run with:
docker compose up --build
