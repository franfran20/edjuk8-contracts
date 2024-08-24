## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

<!-- August 12th -->
<!-- Stopped at implementing all the getters in all contracts required for the UI  -->
<!-- Implement Meta Tx's -->
<!-- Clean up code and add natspec -->

<!-- August 13th -->
<!-- write unit test for the contracts -->
<!-- Deloy the contracts to Open Campus Testnet and verify -->

<!-- August 14th - 16th -->
<!-- Integrate privy into the frontend and allow external wallet connection -->
<!-- Build out the frontend with Next JS and dummy data using mockaroo -->

<!-- August 17th - 18th -->
<!-- Integrate the wallets and use actual data in the frontend for read and write functionality -->
<!-- upload to github this way -->

<!-- August 19th - 25th -->
<!-- add the gasless transaction functionality to the frontend -->
<!-- clean up and populate the frontend for build and deployment -->
<!-- deploy the frontend and populate the Readme for meaningful information -->
<!-- Set up the docs using the docs platform you used for angel protocol alongside excalidraw sketched -->

<!-- August 26th -->
<!-- submit the project to dorahacks -->

<!-- Things to look out for -->
