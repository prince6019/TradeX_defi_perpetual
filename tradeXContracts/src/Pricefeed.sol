// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {console} from "forge-std/Test.sol";

library Pricefeed {
    uint256 private constant DECIMALS_PRECISION = 1e18;
    uint256 private constant PRICEFEED_PRECISION = 1e10;

    // Gets the price of 1 eth in usd
    // returns the price with 1e18 decimals precision
    function getEthInUsd(
        AggregatorV3Interface pricefeed
    ) public view returns (uint256) {
        (, int answer, , , ) = pricefeed.latestRoundData();
        return uint256(answer) * PRICEFEED_PRECISION;
    }

    // input is usd with 18 decimal precision and convert it to amount to ethers.
    function convertUsdToEth(
        uint256 amount, // usd amount in 18 decimals precision
        AggregatorV3Interface pricefeed
    ) public view returns (uint256) {
        uint256 ethInUsd = getEthInUsd(pricefeed);
        uint256 x = amount * DECIMALS_PRECISION;
        return x / ethInUsd;
    }

    // gets the eth with 18 decimals precision and convert to usd with 18 decimals precision.
    function convertEthToUsd(
        uint256 _amount,
        AggregatorV3Interface pricefeed
    ) public view returns (uint256) {
        uint256 ethPrice = getEthInUsd(pricefeed);
        return (ethPrice * _amount) / DECIMALS_PRECISION;
    }
}
