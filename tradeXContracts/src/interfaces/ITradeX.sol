// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ITradeX {
    function openPosition(
        uint256 _collateral,
        uint256 _size,
        bool _isLong
    ) external {}

    function increasePosition(uint256 _size) external {}

    function decreasePosition(uint256 _size) external {}

    function updateCollateral(uint256 _collateral) external {}

    function decreaseCollateral(uint256 _amount) external {}

    function calculateUserPnL(
        address _user
    )
        public
        view
        returns (
            uint256 userPnl,
            uint isProfit /* 0 -> neutral ,1->profit , 2 -> loss*/
        )
    {}

    function getOpenInterest() external view returns (uint256) {}

    function getMaxUtilization() external view returns (uint256) {}
}
