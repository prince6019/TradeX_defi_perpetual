// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Script, console2} from "forge-std/Script.sol";
import {TradeX} from "../src/TradeX.sol";
import {HelperConfig} from "./HelperConfig.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LiquidityPool} from "../src/liquidityPool.sol";

contract deployTrade is Script {
    // IERC20 asset  = IERC20(0x68194a729C2450ad26072b3D33ADaCbcef39D574);

    function run() public returns (TradeX, HelperConfig, LiquidityPool) {
        HelperConfig helperConfig = new HelperConfig();
        (address pricefeed, address mockDai) = helperConfig
            .networkConfigAddress();
        vm.startBroadcast();
        LiquidityPool liquidityVault = new LiquidityPool(IERC20(mockDai));
        TradeX tradeX = new TradeX(
            pricefeed,
            address(liquidityVault),
            IERC20(mockDai)
        );
        vm.stopBroadcast();
        return (tradeX, helperConfig, liquidityVault);
    }
}
