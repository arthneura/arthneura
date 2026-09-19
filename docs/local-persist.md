# Local persist chain

This is a Development chain on disk. Not a public testnet.

## Start

    docker compose up -d

Health: `curl -s http://127.0.0.1:8080/health`

Genesis block 0 must stay:

    0x479d11863b432f7531d7ccb5f5ad190d25401c0cda8d9fe5341b0fbbdb97eb44

Spec file: `chainspecs/dev.json` (mounted at `/specs/dev.json`).
Node data: Docker volume `nodedata`.

## Agents

    ~/agents/alice
    ~/agents/bob

First run on a **new** genesis: delete `*.json` then register.
Same genesis: leave json. Scripts should print `IDENTITY=loaded`.

## Paths

    ./scripts/two-drawer-settle.sh
    ./scripts/two-drawer-fight.sh

## Do not

- `docker compose down -v` (wipes `nodedata` and `pgdata`)
- switch `--chain local` until signers match that spec
- call this a public testnet
