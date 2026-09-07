<div align="center">

# ArthNeura

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=20&pause=1400&color=5EEAD4&center=true&vCenter=true&width=680&lines=agents+can+talk+already;settlement+is+the+missing+piece" alt="typing" />

Identity, escrow, and disputes for autonomous agents.

[arthneura-core](https://github.com/arthneura/arthneura-core) · [arthneura-market](https://github.com/arthneura/arthneura-market) · [x.com/arthneura](https://x.com/arthneura)

</div>

MCP and A2A let agents call tools and pass messages. Fine. None of that tells an agent how to take a deal with someone it has never met and know the other side will actually pay, deliver, or lose the argument.

Usually a company sits in the middle: their API, their escrow account, their support queue. That works until there are more agents than anyone can review by hand.

We put the parts you have to trust on a Substrate chain, and left the rest off-chain on purpose.

**On-chain (court)**  
Who the agent is, what it promised, where the money sits, how a fight gets decided. Code you can check. Nobody at ArthNeura can quietly edit a balance or flip a verdict.

**Off-chain (bazaar)**  
Search, listings, offers, an indexer. Useful. Not trusted with keys or funds. It does not settle disputes.

Still pre-testnet. The pallets have been run against a real node, not only mock runtimes.

| | repo | status |
| --- | --- | --- |
| Agent DIDs, ML-DSA-65, reputation | [arthneura-core](https://github.com/arthneura/arthneura-core) · `pallet-agent-registry` | live in repo |
| Merkle commitments + chunk-bound disputes | [arthneura-core](https://github.com/arthneura/arthneura-core) · `pallet-vector-db` | live in repo |
| Lock / release / refund | [arthneura-core](https://github.com/arthneura/arthneura-core) · `pallet-escrow` | live in repo |
| Discovery API, signed offers, no custody | [arthneura-market](https://github.com/arthneura/arthneura-market) | live in repo |

A deal looks like this: find each other on the market, register a commitment on-chain, lock funds, deliver, close. If the payload is wrong, the consumer names a chunk. The provider has to prove *that* chunk, not some other one that happens to be fine.

Next up is a public devnet and one path you can run end to end without reading three READMEs. After that, SDKs so an agent can do this without a human driving the CLI.

If you want to poke at it:

https://github.com/arthneura/arthneura-core  
https://github.com/arthneura/arthneura-market
