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

--->
there should be functions :--

1. deposit liquidity -- anyone can access it, deposit liquid in the form of dai only and quivalent shares.
2. withdraw liquidity -- only liquid depositor can call it , can withdraw their dai by burning of shares they have.
3. openposition -- anybody can open a posiiton. with given size and collateral and collateral should be in dai and size in eth.size ahould be under max_leverage
   if position is short openinterest = size and if psoition is long than openinterest can be from 0 to infinite.
4. closeposition -- can only be called by open position user. calculate pnl --> if it is profit transefer profit in dai and subtract from total liquidity and if it is loss subtract from collateral in dai and add to liquidity send the rest to the user. subtract the size from openinterest.
5. increaseposition -- only positoned user can call. posiiton should be within max_leverage.calculate the pnl of user's position if it is profit then trasnfer the
   amount of dai from the liquidity and if it is in loss then collateral - loss and continue if it is within leverage.openinterest + increased size.
6. decereasePosiiton -- only positioned user can call. posiiton
7. increasaecollatral
8. decereasecollateral
<!-- Explicit type conversion not allowed from non-payable "address" to "contract LiquidityPool", which has a payable fallback function. -->
