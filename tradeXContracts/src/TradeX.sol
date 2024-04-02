// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// erc20s
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {console} from "forge-std/Test.sol";

// chainlink pricefeed
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Pricefeed} from "./Pricefeed.sol";
import {LiquidityPool} from "./liquidityPool.sol";

error parameter_not_correct();
error over_leverage();
error Position_opened();
error Position_never_opened();
error under_leverage();
error Not_owner_of_position();

contract TradeX {
    using SafeERC20 for IERC20;
    AggregatorV3Interface private immutable i_priceFeed;
    LiquidityPool private liquidityVault;
    IERC20 private immutable i_dai;

    struct Position {
        uint256 isLong; //long - > 1 , short -> 2
        uint256 collateral;
        uint256 sizeInEth;
        uint256 sizeInUsd;
        uint256 LiqPrice;
    }

    // state variables
    uint256 private constant MAX_LEVERAGE = 2000;
    uint256 private constant LEVERAGE_PRECISION = 100;
    uint256 private constant LEVERAGE_DECIMALS = 2;
    uint256 private s_openInterest;
    uint256 private constant borrowing_fees_percentage = 10;
    uint256 constant seconds_in_year = 365 * 24 * 60 * 60;
    uint256 constant liquidator_fee = 10; // 10% of the collateral
    // uint256 position_fee =0.1% of position size; whenever the position changes

    mapping(address => Position) public positionMeta;

    // events
    event positionOpened(
        address indexed trader,
        uint256 indexed Long,
        uint256 collateral,
        uint256 size,
        uint256 sizeInUsd,
        uint256 LiqPrice
    );
    event positionIncreased(
        address indexed trader,
        uint256 indexed Long,
        uint256 collateral,
        uint256 size,
        uint256 sizeInUsd,
        uint256 LiqPrice
    );
    event positionDecreased(
        address indexed trader,
        uint256 indexed Long,
        uint256 collateral,
        uint256 size,
        uint256 sizeInUsd,
        uint256 LiqPrice,
        uint256 pnl
    );
    event positionClosed(
        address indexed trader,
        uint256 indexed Long,
        uint256 collateral,
        uint256 size,
        uint256 sizeInUsd,
        uint256 LiqPrice,
        uint256 pnl
    );

    event collateralIncreased(
        address indexed trader,
        uint256 indexed Long,
        uint256 collateral,
        uint256 size,
        uint256 sizeInUsd,
        uint256 LiqPrice
    );
    event collateralDecreased(
        address indexed trader,
        uint256 indexed Long,
        uint256 collateral,
        uint256 size,
        uint256 sizeInUsd,
        uint256 LiqPrice
    );
    event liquidatePosition(
        address indexed trader,
        uint256 indexed Long,
        uint256 collateral,
        uint256 size,
        uint256 sizeInUsd,
        uint256 LiqPrice
    );

    constructor(address _aggregatorV3, address _liquidityVault, IERC20 _dai) {
        i_priceFeed = AggregatorV3Interface(_aggregatorV3);
        liquidityVault = LiquidityPool(_liquidityVault);
        i_dai = _dai;
    }

    function openPosition(
        uint256 _collateral, //1000 dai
        uint256 _size, //2.5eth
        bool _isLong // true
    ) external {
        if (
            _size < 1e15 ||
            _collateral < 2e18 ||
            positionMeta[msg.sender].isLong >= 1
        ) revert parameter_not_correct();

        uint256 platformFee = calculatePositionFee(_size);
        uint256 _sizeInUsd = Pricefeed.convertEthToUsd(_size, i_priceFeed); // 5000$
        uint256 _leverage = calculateLeverage(
            _sizeInUsd,
            _collateral - platformFee
        ); // 5x
        if (
            _leverage >= MAX_LEVERAGE ||
            s_openInterest + _sizeInUsd > getMaxUtilization()
        ) revert over_leverage();

        i_dai.safeTransferFrom(msg.sender, address(this), _collateral);
        uint256 ethExitPrice = calculateExitPrice(
            _sizeInUsd,
            _size,
            _collateral - platformFee
        ); // 1700$
        positionMeta[msg.sender] = Position(
            _isLong ? 1 : 2,
            _collateral - platformFee,
            _size,
            _sizeInUsd,
            ethExitPrice
        );
        s_openInterest += _sizeInUsd;
        emit positionOpened(
            msg.sender,
            _isLong ? 1 : 2,
            _collateral - platformFee,
            _size,
            _sizeInUsd,
            ethExitPrice
        );
    }

    // size == 2.5eth
    function increasePosition(uint256 _size) external {
        Position memory _tmp = positionMeta[msg.sender];
        if (_tmp.isLong < 1) revert Position_never_opened();
        address _user = msg.sender;
        uint256 platformFee = calculatePositionFee(_size);
        uint256 _totalSizeInEth = _tmp.sizeInEth + _size; // 5eth
        uint256 _sizeInUsd = Pricefeed.convertEthToUsd(_size, i_priceFeed); //5250$
        uint256 _totalSizeInUsd = _sizeInUsd + _tmp.sizeInUsd; // if 1 eth == 2100 then == 10250$

        uint256 _leverage = calculateLeverage(
            _totalSizeInUsd,
            _tmp.collateral - platformFee
        );
        if (
            _leverage > MAX_LEVERAGE ||
            s_openInterest + _sizeInUsd > getMaxUtilization()
        ) revert over_leverage();

        uint256 ethLiqPrice = calculateExitPrice(
            _totalSizeInUsd,
            _totalSizeInEth,
            _tmp.collateral - platformFee
        );

        positionMeta[_user].sizeInEth += _size;
        positionMeta[_user].sizeInUsd = _totalSizeInUsd;
        positionMeta[_user].LiqPrice = ethLiqPrice;
        positionMeta[msg.sender].collateral -= platformFee;
        s_openInterest += _sizeInUsd;

        Position memory updatedPos = positionMeta[_user];

        emit positionIncreased(
            _user,
            _tmp.isLong,
            updatedPos.collateral,
            updatedPos.sizeInEth,
            updatedPos.sizeInUsd,
            updatedPos.LiqPrice
        );
    }

    function updateCollateral(uint256 _collateral) external {
        if (positionMeta[msg.sender].isLong < 1) revert Position_never_opened();
        require(_collateral > 2e18, "_collateral too small");
        Position memory tmp = positionMeta[msg.sender];
        i_dai.safeTransferFrom(msg.sender, address(this), _collateral);
        uint256 ethExitPrice = calculateExitPrice(
            tmp.sizeInUsd,
            tmp.sizeInEth,
            tmp.collateral + _collateral
        );
        positionMeta[msg.sender].LiqPrice = ethExitPrice;
        positionMeta[msg.sender].collateral += _collateral;

        emit collateralIncreased(
            msg.sender,
            tmp.isLong,
            tmp.collateral + _collateral,
            tmp.sizeInEth,
            tmp.sizeInUsd,
            ethExitPrice
        );
    }

    function decreasePosition(uint256 _size) external {
        Position memory _tmpPos = positionMeta[msg.sender];
        if (_tmpPos.collateral == 0) revert Position_never_opened();
        if (_size == _tmpPos.sizeInEth) {
            closePosition(msg.sender);
            return;
        }
        uint256 platformFee = calculatePositionFee(_size);
        uint256 _sizeinUsd = (Pricefeed.getEthInUsd(i_priceFeed) *
            (_tmpPos.sizeInEth - _size)) / 1e18;
        (uint256 pnl, uint256 isProfit) = calculateUserPnL(msg.sender);

        if (isProfit == 1) {
            liquidityVault.transferOut(msg.sender, pnl);
        } else if (isProfit == 2) {
            positionMeta[msg.sender].collateral -= pnl;
            if (
                calculateLeverage(
                    _sizeinUsd,
                    _tmpPos.collateral - platformFee
                ) > MAX_LEVERAGE
            ) revert();
        }
        positionMeta[msg.sender].sizeInEth -= _size;
        positionMeta[msg.sender].sizeInUsd = _sizeinUsd;
        uint256 ethExitPrice = calculateExitPrice(
            _sizeinUsd,
            _tmpPos.sizeInEth - _size,
            _tmpPos.collateral - platformFee
        );
        positionMeta[msg.sender].LiqPrice = ethExitPrice;
        positionMeta[msg.sender].collateral -= platformFee;
        s_openInterest -= Pricefeed.convertEthToUsd(_size, i_priceFeed);

        Position memory updatedPos = positionMeta[msg.sender];

        emit positionDecreased(
            msg.sender,
            _tmpPos.isLong,
            updatedPos.collateral,
            updatedPos.sizeInEth,
            updatedPos.sizeInUsd,
            updatedPos.LiqPrice,
            pnl
        );
    }

    function decreaseCollateral(uint256 _amount) external {
        Position memory _tmPos = positionMeta[msg.sender];
        if (_tmPos.collateral == 0) revert Position_never_opened();
        uint256 _sizeInUsd = _tmPos.sizeInUsd;
        if (_amount == _tmPos.collateral) {
            closePosition(msg.sender);
            return;
        }
        uint256 _newCollateral = _tmPos.collateral - _amount;
        uint256 _leverage = calculateLeverage(_sizeInUsd, _newCollateral);
        if (_leverage > MAX_LEVERAGE) revert over_leverage();
        uint256 ethExitPrice = calculateExitPrice(
            _sizeInUsd,
            _tmPos.sizeInEth,
            _newCollateral
        );
        positionMeta[msg.sender].collateral -= _amount;
        positionMeta[msg.sender].LiqPrice = ethExitPrice;
        emit collateralDecreased(
            msg.sender,
            _tmPos.isLong,
            _newCollateral,
            _tmPos.sizeInEth,
            _tmPos.sizeInUsd,
            ethExitPrice
        );
    }

    function closePosition(address _user) public {
        if (msg.sender != _user && msg.sender != address(this))
            revert Not_owner_of_position();
        Position memory _tmpPos = positionMeta[_user];
        if (_tmpPos.collateral == 0) revert Position_never_opened();
        (uint256 _Pnl, uint256 _isProfit) = calculateUserPnL(_user);
        if (_isProfit == 1) {
            liquidityVault.transferOut(_user, _Pnl);
            i_dai.safeTransfer(_user, _tmpPos.collateral);
        } else if (_isProfit == 2) {
            liquidityVault.transferOut(
                _user,
                positionMeta[_user].collateral - _Pnl
            );
        } else {
            i_dai.safeTransfer(_user, _tmpPos.collateral);
        }

        s_openInterest -= _tmpPos.sizeInUsd;
        delete positionMeta[_user];
        emit positionClosed(
            _user,
            _tmpPos.isLong,
            _tmpPos.collateral,
            _tmpPos.sizeInEth,
            _tmpPos.sizeInUsd,
            _tmpPos.LiqPrice,
            _Pnl
        );
    }

    function liquidate(address _user) external {
        Position memory tmp = positionMeta[_user];
        if (calculateLeverage(tmp.sizeInUsd, tmp.collateral) < MAX_LEVERAGE)
            revert under_leverage();
        uint256 _liquidatorPer = tmp.collateral / liquidator_fee;
        uint256 remainingCollateral = tmp.collateral - _liquidatorPer;
        i_dai.safeTransferFrom(address(this), msg.sender, _liquidatorPer);
        i_dai.safeTransferFrom(
            address(this),
            address(liquidityVault),
            remainingCollateral
        );

        s_openInterest -= positionMeta[_user].sizeInUsd;
        delete positionMeta[_user];
        emit liquidatePosition(
            _user,
            tmp.isLong,
            tmp.collateral,
            tmp.sizeInEth,
            tmp.sizeInUsd,
            tmp.LiqPrice
        );
    }

    function calculateUserPnL(
        address _user
    )
        public
        view
        returns (
            uint256 userPnl,
            uint isProfit /* 0 -> neutral ,1->profit , 2 -> loss*/
        )
    {
        Position memory user = positionMeta[_user];
        if (user.isLong < 1) revert Position_never_opened();
        // uint256 _leverage;
        uint256 currentSizeValue = (positionMeta[_user].sizeInEth *
            getEthInUsd()) / 1e18;
        if (user.isLong == 1) {
            if (currentSizeValue > user.sizeInUsd) {
                userPnl = currentSizeValue - user.sizeInUsd;
                isProfit = 1;
            } else if (currentSizeValue < user.sizeInUsd) {
                userPnl = user.sizeInUsd - currentSizeValue;
                isProfit = 2;
            } else {
                userPnl = 0;
                isProfit = 0;
            }
        } else {
            if (currentSizeValue > user.sizeInUsd) {
                userPnl = currentSizeValue - user.sizeInUsd;
                isProfit = 2;
            } else if (currentSizeValue < user.sizeInUsd) {
                userPnl = user.sizeInUsd - currentSizeValue;
                isProfit = 1;
            } else {
                userPnl = 0;
                isProfit = 0;
            }
        }
        return (userPnl, isProfit);
    }

    /////////////////////
    // View Functions///
    ///////////////////

    function calculateExitPrice(
        uint256 _sizeInUsd,
        uint256 _size,
        uint256 _collateral
    ) public pure returns (uint256 y) {
        uint256 x = _collateral - (_sizeInUsd / MAX_LEVERAGE) * 100;
        y = ((_sizeInUsd - x) / _size) * 1e18;
        return y;
    }

    function getEthInUsd() public view returns (uint256) {
        return Pricefeed.getEthInUsd(i_priceFeed);
    }

    function calculateLeverage(
        uint256 _sizeInUsd,
        uint256 _collateral
    ) public pure returns (uint256) {
        uint256 _leverage = ((_sizeInUsd * LEVERAGE_PRECISION) / _collateral);
        return _leverage;
    }

    function calculatePositionFee(
        uint256 _sizeInEth
    ) public view returns (uint256) {
        uint256 _sizeInUsd = Pricefeed.convertEthToUsd(_sizeInEth, i_priceFeed);
        uint256 _fee = _sizeInUsd / 1000;
        return _fee;
    }

    function calculateBorrowingFee(
        uint256 _size
    ) public view returns (uint256) {
        uint256 _sizeInUsd = Pricefeed.convertEthToUsd(_size, i_priceFeed);
        uint256 _fee = 1e18 / (seconds_in_year * borrowing_fees_percentage);
        return (_sizeInUsd * _fee) / 1e18;
    }

    function getMaxUtilization() public view returns (uint256) {
        return (liquidityVault.getTotalLiquidity() * 8) / 10;
    }

    function getOpenInterest() external view returns (uint256) {
        return s_openInterest;
    }

    function getTraderPostion(
        address _user
    ) external view returns (Position memory) {
        return positionMeta[_user];
    }

    function getMaxLeverage() external pure returns (uint256) {
        return MAX_LEVERAGE;
    }

    function getLeverageDecimals() external pure returns (uint256) {
        return LEVERAGE_DECIMALS;
    }
}
