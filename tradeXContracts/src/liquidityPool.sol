// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ITradeX} from "./interfaces/ITradeX.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LiquidityPool is ERC4626, Ownable {
    using SafeERC20 for IERC20;
    uint256 private s_totalLiquidity;
    ITradeX private tradeX;
    IERC20 private immutable i_dai;
    bool private isInitialize;

    constructor(
        IERC20 _asset
    ) ERC4626(_asset) ERC20("TradeX Coin", "TXC") Ownable(msg.sender) {
        i_dai = _asset;
        isInitialize = false;
    }

    function _initialize(address _tradeX) external onlyOwner {
        if (isInitialize) revert();
        tradeX = ITradeX(_tradeX);
    }

    function updateTradeX(address _tradeX) external onlyOwner {
        tradeX = ITradeX(_tradeX);
    }

    function deposit(
        uint256 _assets,
        address _receiver
    ) public override returns (uint256 shares) {
        shares = super.deposit(_assets, _receiver);
        s_totalLiquidity += _assets;
    }

    // withdraw liquidity by liquidity providers
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    ) public override returns (uint256 shares) {
        if (tradeX.getOpenInterest() + _assets > getMax_Utilization()) revert();
        shares = super.withdraw(_assets, _receiver, _owner);
        s_totalLiquidity -= _assets;
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override returns (uint256 assets) {
        super.mint(shares, receiver);
        s_totalLiquidity += assets;
    }

    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) public override returns (uint256 assets) {
        super.redeem(_shares, _receiver, _owner);
        s_totalLiquidity -= assets;
    }

    function transferOut(address _receiver, uint _amount) external {
        if (_amount > getMax_Utilization()) revert();
        i_dai.safeTransfer(_receiver, _amount);
        s_totalLiquidity -= _amount;
    }

    function getTotalLiquidity() external view returns (uint256) {
        return s_totalLiquidity;
    }

    function getMax_Utilization() public view returns (uint256) {
        return tradeX.getMaxUtilization();
    }
}
