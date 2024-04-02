// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    networkAddress public networkConfigAddress;

    struct networkAddress {
        address pricefeed;
        address dai;
    }

    constructor() {
        if (block.chainid == 11155111) {
            networkConfigAddress = sepoliaEthConfig();
        } else if (block.chainid == 80001) {
            networkConfigAddress = mumbaiEthConfig();
        } else {
            networkConfigAddress = anvilEthConfig();
        }
    }

    function sepoliaEthConfig() public pure returns (networkAddress memory) {
        networkAddress memory _sepoliaConfig = networkAddress({
            pricefeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            dai: 0x68194a729C2450ad26072b3D33ADaCbcef39D574
        });
        return _sepoliaConfig;
    }

    function mumbaiEthConfig() public pure returns (networkAddress memory) {
        networkAddress memory _mumbaiConfig = networkAddress({
            pricefeed: 0x0715A7794a1dc8e42615F059dD6e406A6594651A,
            dai:0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F

        });
        return _mumbaiConfig;
    }

    function anvilEthConfig() public returns (networkAddress memory) {
        if(networkConfigAddress.pricefeed != address(0)){
            return networkConfigAddress;
        }
        vm.startBroadcast();
        MockV3Aggregator mockV3 = new MockV3Aggregator(8, 2000e8);
        ERC20Mock mockDai = new ERC20Mock();
        vm.stopBroadcast();
        networkAddress memory _anvilConfig = networkAddress({
            pricefeed: address(mockV3),
            dai:address(mockDai)
        });

        return _anvilConfig;
    }
}
