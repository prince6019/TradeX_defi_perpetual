// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TradeX} from "../src/TradeX.sol";
import {deployTrade} from "../script/deployTrade.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {HelperConfig} from "../script/HelperConfig.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {LiquidityPool} from "../src/liquidityPool.sol";
import {Pricefeed} from "../src/Pricefeed.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract tradeXTest is Test {
    error Position_never_opened();
    error over_leverage();
    error parameter_not_correct();
    error under_leverage();

    TradeX tradeX;
    HelperConfig helperConfig;
    deployTrade _deployTradeX;
    LiquidityPool liquidityVault;
    AggregatorV3Interface public s_aggregatorInterface;
    address public i_dai;
    address public constant LIQ_PROVIDER_1 = address(1);
    address public constant LIQ_PROVIDER_2 = address(2);
    address public constant TRADER_1 = address(4);
    address public constant TRADER_2 = address(5);
    address public constant liquidtyPoolOwner =
        0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    uint256 public constant liquidity_deposit_amount = 2000 ether; //2000 dai
    uint256 public constant trader_collateral_amount = 200 ether; // 200 dai
    uint256 public constant trader_dai_balance = 400 ether; // total dai = 400dai
    uint256 public constant max_utilization = 80;
    uint256 public constant trader_size = 5e17;
    uint256 public constant max_leverage = 2000;

    function setUp() public {
        _deployTradeX = new deployTrade();
        (tradeX, helperConfig, liquidityVault) = _deployTradeX.run();
        (address pricefeed, address mockDai) = helperConfig
            .networkConfigAddress();
        s_aggregatorInterface = AggregatorV3Interface(pricefeed);
        i_dai = mockDai;
        IERC20 daiMock = IERC20(mockDai);
        ERC20Mock(mockDai).mint(LIQ_PROVIDER_1, liquidity_deposit_amount);
        ERC20Mock(mockDai).mint(LIQ_PROVIDER_2, liquidity_deposit_amount);
        ERC20Mock(mockDai).mint(TRADER_1, trader_dai_balance);
        ERC20Mock(mockDai).mint(TRADER_2, trader_dai_balance);
        vm.prank(LIQ_PROVIDER_1);
        daiMock.approve(address(liquidityVault), liquidity_deposit_amount);
        vm.prank(LIQ_PROVIDER_2);
        daiMock.approve(address(liquidityVault), liquidity_deposit_amount);
        vm.prank(TRADER_1);
        daiMock.approve(address(tradeX), trader_collateral_amount);
        vm.prank(TRADER_2);
        daiMock.approve(address(tradeX), trader_collateral_amount);
        vm.prank(liquidtyPoolOwner);
        liquidityVault._initialize(address(tradeX));
    }

    // modifiers ------
    modifier depositLiquidity() {
        vm.prank(LIQ_PROVIDER_1);
        liquidityVault.deposit(liquidity_deposit_amount, LIQ_PROVIDER_1);
        vm.prank(LIQ_PROVIDER_2);
        liquidityVault.deposit(liquidity_deposit_amount, LIQ_PROVIDER_2);
        _;
    }

    modifier openLongPosition() {
        vm.prank(LIQ_PROVIDER_1);
        liquidityVault.deposit(liquidity_deposit_amount, LIQ_PROVIDER_1);
        vm.prank(LIQ_PROVIDER_2);
        liquidityVault.deposit(liquidity_deposit_amount, LIQ_PROVIDER_2);
        vm.prank(TRADER_1);
        tradeX.openPosition(trader_collateral_amount, trader_size, true);
        _;
    }

    // helper functions -----
    // uint test starts ---
    function testDepositFunction() public depositLiquidity {
        assertEq(
            liquidityVault.getTotalLiquidity(),
            2 * liquidity_deposit_amount
        );
    }

    function testWithdrawByTrader() public depositLiquidity {
        vm.prank(TRADER_1);
        vm.expectRevert();
        liquidityVault.withdraw(liquidity_deposit_amount, TRADER_1, TRADER_1);
    }

    function testWithdrawByLiqProvider() public depositLiquidity {
        vm.startPrank(LIQ_PROVIDER_1);
        console.log(
            "balance before : ",
            IERC20(i_dai).balanceOf(LIQ_PROVIDER_1)
        );

        liquidityVault.withdraw(
            liquidity_deposit_amount,
            LIQ_PROVIDER_1,
            LIQ_PROVIDER_1
        );
        console.log("balance after:", IERC20(i_dai).balanceOf(LIQ_PROVIDER_1));
        assertEq(
            IERC20(i_dai).balanceOf(LIQ_PROVIDER_1),
            liquidity_deposit_amount
        );
        vm.stopPrank();
    }

    function testGetMaxUtilization() public depositLiquidity {
        console.log("max utiliaxtion : ", liquidityVault.getMax_Utilization());
        assertEq(
            liquidityVault.getMax_Utilization(),
            (2 * liquidity_deposit_amount * max_utilization) / 100
        );
    }

    function testOpenPositionRevertsIfOverLeverage() public depositLiquidity {
        vm.prank(TRADER_1);
        vm.expectRevert(over_leverage.selector);
        // leverage is 20x
        tradeX.openPosition(trader_collateral_amount, 2 ether, true);
    }

    function testOpenPositionrevertsIfMax_utilize() public depositLiquidity {
        vm.prank(TRADER_1);
        vm.expectRevert(over_leverage.selector);
        // max utilize = 3200e18 $ and size in here is 3600e18 $
        tradeX.openPosition(trader_collateral_amount, 19e17, true);
    }

    function testOPenPosition() public depositLiquidity {
        vm.startPrank(TRADER_1);
        tradeX.openPosition(trader_collateral_amount, trader_size, true);
        // uint256 ethPrice = Pricefeed.getEthInUsd(s_aggregatorInterface);
        uint256 _sizeInUsd = Pricefeed.convertEthToUsd(
            trader_size,
            s_aggregatorInterface
        );
        uint256 openInterest = Pricefeed.convertEthToUsd(
            trader_size,
            s_aggregatorInterface
        );
        vm.stopPrank();
        console.log("open interest ---", openInterest / 1e18);
        assertEq(tradeX.getOpenInterest(), openInterest);

        (
            uint256 isLong,
            uint256 collateral,
            uint256 sizeInEth,
            uint256 sizeInUSd,
            uint256 Liqprice
        ) = tradeX.positionMeta(TRADER_1);
        assertEq(isLong, 1);
        assertEq(sizeInEth, trader_size);
        assertEq(sizeInUSd, _sizeInUsd);
        console.log("collateral :", collateral / 1e18);
        console.log("Liquidation Price :", Liqprice / 1e18);
    }

    function testincreasePositionRevert() public openLongPosition {
        vm.prank(TRADER_2);
        vm.expectRevert(Position_never_opened.selector);
        tradeX.increasePosition(trader_size);
    }

    function testIncreasePositionRevertIfOverleverage()
        public
        openLongPosition
    {
        vm.prank(TRADER_1);
        vm.expectRevert(over_leverage.selector);
        tradeX.increasePosition(2 ether);
    }

    function testIncreaseSizeOfposition() public openLongPosition {
        vm.startPrank(TRADER_1);
        (, uint256 previousCollateral, , , ) = tradeX.positionMeta(TRADER_1);
        tradeX.increasePosition(trader_size);
        uint256 openInterest = Pricefeed.convertEthToUsd(
            trader_size,
            s_aggregatorInterface
        );
        console.log(
            "open interest after increasing position ",
            openInterest / 1e18
        );
        (, uint256 collateral, uint256 size, , uint256 LiqPrice) = tradeX
            .positionMeta(TRADER_1);
        uint256 _sizeInUsd = Pricefeed.convertEthToUsd(
            size,
            s_aggregatorInterface
        );
        uint256 exitPrice = tradeX.calculateExitPrice(
            _sizeInUsd,
            size,
            collateral
        );
        uint256 platformFee = tradeX.calculatePositionFee(trader_size);
        vm.stopPrank();
        assertEq(2 * openInterest, tradeX.getOpenInterest());
        assertEq(size, 2 * trader_size);
        assertEq(LiqPrice, exitPrice);
        assertEq(collateral, previousCollateral - platformFee);
        console.log("collateral after increasing size : ", collateral / 1e18);
        console.log("liq price after increasing size : ", LiqPrice / 1 ether);
        console.log(
            "leverage of position :",
            tradeX.calculateLeverage(_sizeInUsd, collateral)
        );
    }

    function testUpdateCollateralRevertsForNotTrader() public openLongPosition {
        vm.prank(TRADER_2);
        vm.expectRevert(Position_never_opened.selector);
        tradeX.updateCollateral(trader_collateral_amount);
    }

    function testUpadateCollateralRevertsForlessCollateral()
        public
        openLongPosition
    {
        vm.prank(TRADER_1);
        vm.expectRevert();
        tradeX.updateCollateral(1e18);
    }

    function testUpdateCollateral() public openLongPosition {
        vm.startPrank(TRADER_1);
        IERC20(i_dai).approve(address(tradeX), trader_collateral_amount);
        (, uint256 previousCollateral, , , ) = tradeX.positionMeta(TRADER_1);
        tradeX.updateCollateral(trader_collateral_amount);
        (
            ,
            uint256 collateral,
            uint256 size,
            uint256 sizeInUsd,
            uint256 LiqPrice
        ) = tradeX.positionMeta(TRADER_1);
        uint256 exitPrice = tradeX.calculateExitPrice(
            sizeInUsd,
            size,
            collateral
        );
        vm.stopPrank();
        assertEq(IERC20(i_dai).balanceOf(TRADER_1), 0);
        assertEq(trader_collateral_amount + previousCollateral, collateral);
        assertEq(LiqPrice, exitPrice);
        console.log("LiqPrice after updating collateral : ", LiqPrice);
        console.log("collateral after updating collateral :", collateral);
    }

    function testDecreasePositionReverts() public {
        vm.prank(TRADER_1);
        vm.expectRevert(Position_never_opened.selector);
        tradeX.decreasePosition(1e17);
    }

    function testdecreasePositionRevertsIfsizeisBig() public openLongPosition {
        vm.startPrank(TRADER_1);
        tradeX.decreasePosition(trader_size);
        uint256 openInterest = tradeX.getOpenInterest();
        (
            uint256 isLong,
            uint256 collateral,
            uint256 size,
            uint256 sizeInUsd,
            uint256 LiqPrice
        ) = tradeX.positionMeta(TRADER_1);
        vm.stopPrank();
        assertEq(openInterest, 0);
        assertEq(isLong, 0);
        assertEq(collateral, 0);
        assertEq(size, 0);
        assertEq(sizeInUsd, 0);
        assertEq(LiqPrice, 0);
    }

    function testdecreasePosition() public openLongPosition {
        uint256 _sizeToDecrease = 1e17; // 0.1 eth
        vm.startPrank(TRADER_1);
        uint256 _sizeInUsd = Pricefeed.convertEthToUsd(
            _sizeToDecrease,
            s_aggregatorInterface
        );
        uint256 _openInterest = tradeX.getOpenInterest();
        (, uint256 previousCollateral, , , ) = tradeX.positionMeta(TRADER_1);
        tradeX.decreasePosition(_sizeToDecrease);
        (, uint256 collateral, , uint256 sizeInUsd, uint256 LiqPrice) = tradeX
            .positionMeta(TRADER_1);
        uint256 previousSizeInUsd = Pricefeed.convertEthToUsd(
            trader_size,
            s_aggregatorInterface
        );
        uint256 platformFee = tradeX.calculatePositionFee(_sizeToDecrease);
        uint256 exitPrice = tradeX.calculateExitPrice(
            previousSizeInUsd - _sizeInUsd,
            trader_size - _sizeToDecrease,
            previousCollateral - platformFee
        );
        vm.stopPrank();
        assertEq(tradeX.getOpenInterest(), _openInterest - _sizeInUsd);
        assertEq(LiqPrice, exitPrice);
        assertEq(collateral, previousCollateral - platformFee);
        assertEq(sizeInUsd, previousSizeInUsd - _sizeInUsd);
    }

    function test_RevertdecreaseCollateral() public openLongPosition {
        uint256 _amount = 150e18;
        vm.startPrank(TRADER_1);
        vm.expectRevert(over_leverage.selector);
        tradeX.decreaseCollateral(_amount);
        vm.stopPrank();
    }

    function test_closePositionIfcollateralisBig() public openLongPosition {
        vm.startPrank(TRADER_1);
        (, uint256 previousCollateral, , , ) = tradeX.positionMeta(TRADER_1);
        tradeX.decreaseCollateral(previousCollateral);
        vm.stopPrank();
        assertEq(tradeX.getOpenInterest(), 0);
    }

    function test_decreaseCollateral() public openLongPosition {
        uint256 amount = 100e18;
        vm.startPrank(TRADER_1);
        (
            ,
            uint256 previousCollateral,
            uint256 previousSize,
            uint256 previousSizeInUsd,

        ) = tradeX.positionMeta(TRADER_1);
        tradeX.decreaseCollateral(amount);
        (, uint256 collateral, , , uint256 LiqPrice) = tradeX.positionMeta(
            TRADER_1
        );
        uint256 exitPrice = tradeX.calculateExitPrice(
            previousSizeInUsd,
            previousSize,
            collateral
        );
        assertEq(previousCollateral - amount, collateral);
        assertEq(LiqPrice, exitPrice);
    }

    function testClosePosition() public openLongPosition {
        vm.startPrank(TRADER_1);
        tradeX.closePosition(TRADER_1);
        (
            uint256 isLong,
            uint256 collateral,
            uint256 size,
            uint256 sizeInUsd,
            uint256 LiqPrice
        ) = tradeX.positionMeta(TRADER_1);
        vm.stopPrank();

        assertEq(tradeX.getOpenInterest(), 0);
        assertEq(isLong, 0);
        assertEq(size, 0);
        assertEq(collateral, 0);
        assertEq(LiqPrice, 0);
        assertEq(sizeInUsd, 0);
    }

    function test_revertsLiquidate() public openLongPosition {
        vm.prank(TRADER_2);
        vm.expectRevert(under_leverage.selector);
        tradeX.liquidate(TRADER_1);
    }

    function test_getMaxLeverage() public {
        assertEq(tradeX.getMaxLeverage(), max_leverage);
        assertEq(tradeX.getLeverageDecimals(), 2);
    }

    function testPricefeedconversionfromusdtoeth() public {
        uint256 amount = 200e18;
        uint256 hamara = Pricefeed.convertUsdToEth(
            amount,
            s_aggregatorInterface
        );
        assertEq(hamara, 1e17);
        console.log("hamara :", hamara);
    }
}
