// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {SafeMath} from './library/SafeMath.sol';
import {SafeERC20} from './library/SafeERC20.sol';
import {Address} from './library/Address.sol';
import {Math} from './library/Math.sol';
import {TickMath} from './library/TickMath.sol';
import {LiquidityAmounts} from './library/LiquidityAmounts.sol';
import {FullMath} from './library/FullMath.sol';

import {VaultAPI} from '../interfaces/IVault.sol';
import {IERC20} from '../interfaces/IERC20.sol';
import {IUniV3} from '../interfaces/IUniV3.sol';
import {IStrategy} from '../interfaces/IStrategy.sol';
import {ILendingHelper} from '../interfaces/ILendingHelper.sol';
import {IUniswapV3MintCallback} from '../interfaces/IUniswapV3MintCallback.sol';
import {IAaveOracle} from '../interfaces/IAaveOracle.sol';

struct Ticks {
    int24 lowerTick;
    int24 upperTick;
}

struct Position {
    uint256 token0;
    uint256 token1;
    uint128 liquidity;
}

enum LimitOrderStatus {Inactive, Bid, Ask}

contract UniswapHelper is IUniswapV3MintCallback {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    Ticks public baseTicks;
    Ticks public limitTicks;
    int24 public tickSpacing;
    int24 public tickWidth = 4000; // for 2200 r = 1.2461 for 4000 r = 1.4918
    int24 public tickRebalanceDeviation = 400; // 10% of the width meanwhile
    int24 public tickLORebalanceDeviation = 20;
    uint16 public limitOrderMaxSize = 500;

    // Only set this to true externally when we want to trigger our keepers to harvest for us
    uint256 public wantDust = 1e4;
    uint256 public wethDust = 1e12;

    IStrategy public strategy;
    ILendingHelper public lendHelper;

    VaultAPI vault;

    // Second rebalance variables
    LimitOrderStatus public limit;
    bool public orderSet;

    bool internal mintStorage;

    // Assets
    address public want;
    address public wETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

    // Constants
    uint256 internal constant basisOne = 10000;
    uint256 internal constant MAX = type(uint256).max; // For uint256

    IUniV3 public uniV3Pool;

    IAaveOracle public constant aaveOracle =
        IAaveOracle(0xb023e699F5a33916Ea823A16485e259257cA8Bd1);

    event LimitPosRebalance(int24 tick, uint256 fees0, uint256 fees1);
    event BasePosRebalance(int24 tick, uint256 fees, uint256 fees1);

    constructor(address _uniV3Pool, address _vault) public {
        uniV3Pool = IUniV3(_uniV3Pool);
        tickSpacing = uniV3Pool.tickSpacing();
        vault = VaultAPI(_vault);
        want = vault.token();
        baseTicks = _getInitialTicks();
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                      Modifiers                                            //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    /**
     * Resolve governance address from Vault contract, used to make assertions on protected functions.
     */
    function governance() internal view returns (address) {
        return vault.governance();
    }

    // TODO add strategist too.
    modifier onlyAuthorized() {
        require(msg.sender == governance() || msg.sender == address(strategy), '!authorized');
        _;
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                   Public  Getters                                         //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function name() external pure returns (string memory) {
        return 'Strategy Uniswap Helper v0.3';
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfWeth() public view returns (uint256) {
        return IERC20(wETH).balanceOf(address(this));
    }

    function getPrincipal() external view returns (Position memory basePosition) {
        (basePosition, ) = _openPositions();
    }

    function getLimitPosition() external view returns (Position memory limitPosition) {
        (, limitPosition) = _openPositions();
    }

    function getBaseTicks() public view returns (int24, int24) {
        return (baseTicks.lowerTick, baseTicks.upperTick);
    }

    function getLimitTicks() public view returns (int24, int24) {
        return (limitTicks.lowerTick, limitTicks.upperTick);
    }

    function getAutoRebalanceTicks() public view returns (int24, int24) {
        (, int24 tick, , , , , ) = uniV3Pool.slot0();
        int24 tickFloor = _floor(tick);
        int24 tickCeil = tickFloor + tickSpacing;
        return (tickFloor - tickWidth, tickCeil + tickWidth);
    }

    function _calcLimitOrderRebalance(uint256 _eta) internal view returns (bool) {
        Position memory limitOrder = _getPosition(limitTicks);
        uint256 wethInUsdc = _wethToWant(limitOrder.token1, true);
        uint256 usdcValue = limitOrder.token0.add(wethInUsdc);
        // TODO: change this to make it more efficient and dynamic without he max Limit order size
        if (usdcValue > _eta.div(10)) {
            if (
                (limit == LimitOrderStatus.Bid && limitOrder.token0 == 0) ||
                (limit == LimitOrderStatus.Ask && limitOrder.token1 == 0)
            ) {
                // (int24 baseLower, int24 baseUpper) = getBaseTicks();
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Trigger to rebalance full positions.
     */
    function rebalanceTrigger() public view returns (bool) {
        if (lendHelper.triggerLend()) return true;
        (, int24 tick, , , , , ) = uniV3Pool.slot0();
        if (tick > baseTicks.lowerTick && tick < baseTicks.upperTick) {
            if (tick - baseTicks.lowerTick <= tickRebalanceDeviation) return true;
            if (baseTicks.upperTick - tick <= tickRebalanceDeviation) return true;
        }
        return false;
    }

    /**
     * @dev Trigger to close the limit order if it has been done and increases base position according storage ticks.
     */
    function addLimitOrderToBaseTrigger() public view returns (bool) {
        if (orderSet == false) return false;
        return _calcLimitOrderRebalance(strategy.estimatedTotalAssets());
    }

    /**
     * @dev Trigger to rebalance the limit order if it has been deprecated and is far from current tick.
     */
    function limitOrderRebalanceTrigger() public view returns (bool) {
        (, int24 tick, , , , , ) = uniV3Pool.slot0();
        if (
            (tick > limitTicks.lowerTick &&
                tick > limitTicks.upperTick + tickLORebalanceDeviation) ||
            (tick < limitTicks.upperTick && tick < limitTicks.lowerTick - tickLORebalanceDeviation)
        ) {
            return true;
        }

        return false;
    }

    function getBalance(uint256 _fees, bool _oracle) external view returns (uint256) {
        (uint256 totalUsdcBalance, uint256 totalWethBalance) = _getPositionsTotalAssets();
        if (totalWethBalance == 0) return totalUsdcBalance;
        uint256 wethInUsdc = _wethToWant(totalWethBalance, _oracle);
        uint256 wethInUsdcMinusFees = wethInUsdc.mul(_fees).div(basisOne);
        return wethInUsdcMinusFees.add(totalUsdcBalance);
    }

    function summary()
        public
        view
        returns (
            uint256 principalInWant,
            Position memory basePosition,
            Position memory limitPosition,
            uint256 amountToken0,
            uint256 amountToken1,
            uint256 estimatedPrincipalFees,
            uint256 estimatedLimitOrderFees
        )
    {
        principalInWant = _calcPrincipalInWant();
        (basePosition, limitPosition) = _openPositions();
        (amountToken0, amountToken1) = _getPositionsTotalAssets();
        estimatedPrincipalFees = estimatePrincipalFees();
        estimatedLimitOrderFees = estimateLimitOrderFees();
    }

    function estimateLimitOrderFees() public view returns (uint256) {
        (, int24 tick, , , , , ) = uniV3Pool.slot0();
        (uint256 wantFee, uint256 wethFee) = _estimateFees(limitTicks, tick);
        // Compute current fees earned
        return wantFee.add(_wethToWant(wethFee, false));
    }

    function estimatePrincipalFees() public view returns (uint256) {
        (, int24 tick, , , , , ) = uniV3Pool.slot0();
        (uint256 wantFee, uint256 wethFee) = _estimateFees(baseTicks, tick);
        // Compute current fees earned
        return wantFee.add(_wethToWant(wethFee, false));
    }

    function calcTickPrice(int24 _tick) public pure returns (uint256) {
        uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(_tick);
        return uint256(2**192).mul(1e18).div(uint256(sqrtPrice).mul(uint256(sqrtPrice)));
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                        External Uni V3 Operations  (protected)                            //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function unwindAllPositions() external onlyAuthorized {
        _unwindAllPositions();
    }

    function setOrders() external onlyAuthorized {
        return _setOrders();
    }

    // In order to be flexible, repay weth for example to reduce collateralRatio and put usdc to work
    function setLimitOrder() external onlyAuthorized {
        _setLimitOrder();
        _sendFundsToStrategy();
    }

    function closeLimitOrderPosition() external onlyAuthorized {
        _unwindPosition(limitTicks);
        _sendFundsToStrategy();
        orderSet = false;
    }

    function renewLimitOrder() external onlyAuthorized {
        _renewLimitOrder();
    }

    function unwindAllAndSetTicks(int24 _newLowerTick, int24 _newUpperTick)
        external
        onlyAuthorized
    {
        _unwindAllAndSetTicks(_newLowerTick, _newUpperTick);
    }

    function withdrawFromPrincipal(uint256 _amountNeeded) external onlyAuthorized {
        uint128 liquidityToBurn = _calcLiquidityToBurn(_amountNeeded);
        if (liquidityToBurn > 0) {
            // Remove our specified liquidity amount & Collect fees on the way
            _burnAndCollectLiquidity(liquidityToBurn, baseTicks);
            _sendFundsToStrategy();
        }
    }

    /**
     * @dev Collects tokens owed to a position from accumulated swap fees or burned liquidity.
     */
    function collectTradingFees() external onlyAuthorized returns (uint256, uint256) {
        (uint128 _liquidityP, , ) = _position(baseTicks);
        (uint128 _liquidityL, , ) = _position(limitTicks);
        (uint256 fees0, uint256 fees1) = (0, 0);
        (uint256 fees0LO, uint256 fees1LO) = (0, 0);
        if (_liquidityP > 0) {
            (fees0, fees1) = _burnAndCollectLiquidity(0, baseTicks);
        }
        if (_liquidityL > 0) {
            (fees0LO, fees1LO) = _burnAndCollectLiquidity(0, limitTicks);
        }
        _sendFundsToStrategy();
        return (fees0.add(fees0LO), fees1.add(fees1LO));
    }

    //--------------------------------//
    //      Uni V3  Callbacks         //
    //--------------------------------//

    /**
     * @dev Callback function of uniswapV3Pool mint.
     *      (Uniswap uses a callback pattern to pull funds from the caller)
     *      Access restricted only for the pool -> Bool storage mintStorage,
     *      needed in case Uniswap were hacked
     */
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata
    ) external override {
        require(msg.sender == address(uniV3Pool));
        // Boolean storage variable to track that the callback was preceded by a call to mintLiquidity
        require(mintStorage == true);
        mintStorage = false;
        if (amount0Owed > 0) IERC20(want).safeTransfer(address(uniV3Pool), amount0Owed);
        if (amount1Owed > 0) IERC20(wETH).safeTransfer(address(uniV3Pool), amount1Owed);
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                             Internal Uni V3 Operations                                    //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function _unwindAllPositions()
        internal
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // Withdraw all liquidity and collect all fees from Uniswap pool
        (uint256 _fees0, uint256 _fees1) = _unwindPosition(baseTicks);
        (uint256 _fees0L, uint256 _fees1L) = _unwindPosition(limitTicks);
        orderSet = false;
        _sendFundsToStrategy();
        return (_fees0, _fees0L, _fees1, _fees1L);
    }

    function _renewLimitOrder() internal {
        (uint256 limit0, uint256 limit1) = _unwindPosition(limitTicks);
        orderSet = false;
        _setLimitOrder();
        _sendFundsToStrategy();
        emit LimitPosRebalance(currentTick(), limit0, limit1);
    }

    function _setOrders() internal {
        _unwindPosition(limitTicks);
        orderSet = false;
        _unwindPosition(baseTicks);
        uint256 wantAmount = _balanceOfWant();
        uint256 wethAmount = _balanceOfWeth();
        _addLiquidity(wantAmount, wethAmount, baseTicks);
        _setLimitOrder();
        _sendFundsToStrategy();
    }

    function _unwindAllAndSetTicks(int24 _newLowerTick, int24 _newUpperTick)
        internal
        returns (uint256 fees0, uint256 fees1)
    {
        (uint256 base0, uint256 limit0, uint256 base1, uint256 limit1) = _unwindAllPositions();
        _setTickParams(_newLowerTick, _newUpperTick);
        emit BasePosRebalance(currentTick(), base0, base1);
        emit LimitPosRebalance(currentTick(), limit0, limit1);
        return (fees0, fees1);
    }

    function _addLiquidity(
        uint256 amount0,
        uint256 amount1,
        Ticks memory _baseTicks
    ) internal returns (uint256, uint256) {
        uint128 _liquidity = _liquidityForAmounts(_baseTicks, amount0, amount1);
        return _mintLiquidity(_liquidity, _baseTicks);
    }

    /**
     * note Deposits liquidity in a range on the Uniswap pool.
     *      Mints liquidity for the desired position.
     * @dev amounts of tokens received from Uniswap Pool functions might be
     *      manipulated by front runners amount0Min & amount1Min mandatory
     */
    function _mintLiquidity(uint128 _liquidity, Ticks memory _ticks)
        internal
        returns (uint256 amount0, uint256 amount1)
    {
        (uint256 _amount0Min, uint256 _amount1Min) = _amountsForLiquidity(_liquidity, _ticks);
        if (_liquidity > 0) {
            mintStorage = true;
            (amount0, amount1) = uniV3Pool.mint(
                address(this),
                _ticks.lowerTick,
                _ticks.upperTick,
                _liquidity,
                abi.encode(0)
            );
            require(amount0 >= _amount0Min && amount1 >= _amount1Min, '!Efficient');
        }
    }

    /**
     * note Burns liquidity for the desired position.
     * @dev Amounts of tokens received from Uniswap.
     *      Pool functions might be manipulated by front runners amount0Min & amount1Min mandatory
     *      Tokens collected may be from accumulated swap fees or burned liquidity
     *      To get the trading fees we need to deduct the amount of token from
     *      liquidity burnt from the total -> fees0 = collect0 - owed0
     *      Burn liquidity: if liquidity = 0 then we poke position
     */
    function _burnAndCollectLiquidity(uint128 _liquidity, Ticks memory _ticks)
        internal
        returns (uint256 fees0, uint256 fees1)
    {
        (uint256 _amount0Min, uint256 _amount1Min) = _amountsForLiquidity(_liquidity, _ticks);
        (uint256 burned0, uint256 burned1) =
            uniV3Pool.burn(_ticks.lowerTick, _ticks.upperTick, _liquidity);
        // Collect tokens owed
        (uint256 amount0, uint256 amount1) =
            uniV3Pool.collect(
                address(this),
                _ticks.lowerTick,
                _ticks.upperTick,
                type(uint128).max,
                type(uint128).max
            ); // Once we have burned liquidity we need to collect
        require(amount0 >= _amount0Min && amount1 >= _amount1Min);
        (fees0, fees1) = (amount0.sub(burned0), amount1.sub(burned1));
    }

    function _unwindPosition(Ticks memory _ticks) internal returns (uint256, uint256) {
        (uint128 _liquidity, , ) = _position(_ticks);
        if (_liquidity > 0) {
            return _burnAndCollectLiquidity(_liquidity, _ticks);
        }
    }

    function _setLimitOrder() internal {
        (uint128 liquidity, Ticks memory orderTicks, LimitOrderStatus _order) =
            _calculateLimitOrder();
        _mintLiquidity(liquidity, orderTicks);
        limitTicks = orderTicks;
        limit = _order;
        orderSet = true;
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                Internal Helper                                            //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function _openPositions() internal view returns (Position memory, Position memory) {
        return (_getPosition(baseTicks), _getPosition(limitTicks));
    }

    function _calcPrincipalInWant() internal view returns (uint256) {
        Position memory base = _getPosition(baseTicks);
        if (base.liquidity == 0) return 0;
        uint256 wethInUsdc = _wethToWant(base.token1, false);
        return wethInUsdc.add(base.token0);
    }

    function _balanceOfWeth() public view returns (uint256) {
        return IERC20(wETH).balanceOf(address(this));
    }

    function _balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function currentTick() public view returns (int24 tick) {
        (, tick, , , , , ) = uniV3Pool.slot0();
    }

    function _sendFundsToStrategy() internal {
        uint256 wantBal = _balanceOfWant();
        uint256 wethBal = _balanceOfWeth();
        if (wantBal > 0) {
            IERC20(want).safeTransfer(address(strategy), wantBal);
        }
        if (wethBal > 0) {
            IERC20(wETH).safeTransfer(address(strategy), wethBal);
        }
        // TODO: add check to make sure the funds have arrived correctly
    }

    /**
     * @dev Depending on how large the limit order is:
     *          - Put all the assets into a limit order to generate Yield.
     *          - Put half of the assets on a Limit order and leave the rest idle,
     *              ready to be added to the principal once the Limit Order is complete.
     */
    function _getLimitOrderAmounts()
        internal
        view
        returns (uint256 wantBalance, uint256 wethBalance)
    {
        wantBalance = balanceOfWant();
        wethBalance = balanceOfWeth();

        uint256 limitOrderSize = wantBalance.add(_wethToWant(wethBalance, false));
        uint16 divideBy = 1;

        uint256 maxOrderSize = strategy.estimatedTotalAssets().mul(limitOrderMaxSize).div(basisOne);

        if (limitOrderSize > maxOrderSize) divideBy = 2;

        if (wantBalance < wantDust) return (wantBalance, wethBalance.div(divideBy));
        if (wethBalance < wethDust) return (wantBalance.div(divideBy), wethBalance);
    }

    /**
     * @dev Wrapper around `LiquidityAmounts.getLiquidityForAmount0()`.
     */
    function _liquidityForAmount0(Ticks memory _ticks, uint256 _amount0)
        internal
        pure
        returns (uint128)
    {
        return
            LiquidityAmounts.getLiquidityForAmount0(
                TickMath.getSqrtRatioAtTick(_ticks.lowerTick),
                TickMath.getSqrtRatioAtTick(_ticks.upperTick),
                _amount0
            );
    }

    /**
     * @dev Wrapper around `LiquidityAmounts.getLiquidityForAmount1()`.
     */
    function _liquidityForAmount1(Ticks memory _ticks, uint256 _amount1)
        internal
        pure
        returns (uint128)
    {
        return
            LiquidityAmounts.getLiquidityForAmount1(
                TickMath.getSqrtRatioAtTick(_ticks.lowerTick),
                TickMath.getSqrtRatioAtTick(_ticks.upperTick),
                _amount1
            );
    }

    /**
     * note Get the amounts of the given numbers of liquidity tokens
     */
    function _amountsForLiquidity(uint128 _liquidity, Ticks memory _ticks)
        internal
        view
        returns (uint256, uint256)
    {
        (uint160 sqrtRatioX96, , , , , , ) = uniV3Pool.slot0();
        // Computes the token0 and token1 value for a given amount of liquidity
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(_ticks.lowerTick),
                TickMath.getSqrtRatioAtTick(_ticks.upperTick),
                _liquidity
            );
    }

    function _computeFeesEarned(
        int24 _currentTick,
        bool _isZero,
        uint256 _feeGrowthInsideLast,
        Ticks memory _ticks,
        uint128 _liquidity
    ) internal view returns (uint256 fee) {
        uint256 feeGrowthOutsideLower;
        uint256 feeGrowthOutsideUpper;
        uint256 feeGrowthGlobal;
        if (_isZero) {
            feeGrowthGlobal = uniV3Pool.feeGrowthGlobal0X128();
            (, , feeGrowthOutsideLower, , , , , ) = uniV3Pool.ticks(_ticks.lowerTick);
            (, , feeGrowthOutsideUpper, , , , , ) = uniV3Pool.ticks(_ticks.upperTick);
        } else {
            feeGrowthGlobal = uniV3Pool.feeGrowthGlobal1X128();
            (, , , feeGrowthOutsideLower, , , , ) = uniV3Pool.ticks(_ticks.lowerTick);
            (, , , feeGrowthOutsideUpper, , , , ) = uniV3Pool.ticks(_ticks.upperTick);
        }

        // Calculate fee growth below
        uint256 feeGrowthBelow;
        if (_currentTick >= _ticks.lowerTick) {
            feeGrowthBelow = feeGrowthOutsideLower;
        } else {
            feeGrowthBelow = feeGrowthGlobal - feeGrowthOutsideLower;
        }

        // Calculate fee growth above
        uint256 feeGrowthAbove;
        if (_currentTick < _ticks.upperTick) {
            feeGrowthAbove = feeGrowthOutsideUpper;
        } else {
            feeGrowthAbove = feeGrowthGlobal - feeGrowthOutsideUpper;
        }

        uint256 feeGrowthInside = feeGrowthGlobal - feeGrowthBelow - feeGrowthAbove;
        fee = FullMath.mulDiv(
            _liquidity,
            feeGrowthInside - _feeGrowthInsideLast,
            0x100000000000000000000000000000000
        );
    }

    /**
     * @dev Wrapper around `LiquidityAmounts.getLiquidityForAmounts()`.
     */
    function _liquidityForAmounts(
        Ticks memory _ticks,
        uint256 _amount0,
        uint256 _amount1
    ) internal view returns (uint128) {
        (uint160 sqrtRatioX96, , , , , , ) = uniV3Pool.slot0();
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(_ticks.lowerTick),
                TickMath.getSqrtRatioAtTick(_ticks.upperTick),
                _amount0,
                _amount1
            );
    }

    function _rawPosition(Ticks memory _ticks, address _strategy)
        internal
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0Last,
            uint256 feeGrowthInside1Last,
            uint128 owed0,
            uint128 owed1
        )
    {
        // Key (owner, tickLower and tickUpper)
        bytes32 key = keccak256(abi.encodePacked(_strategy, _ticks.lowerTick, _ticks.upperTick));
        // Returns the info about a position by the position's key
        return uniV3Pool.positions(key);
    }

    /**
     * note Rounds tick down towards negative infinity,
     *      so that it's a multiple of `tickSpacing`.
     */
    function _floor(int24 tick) internal view returns (int24) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;
        return compressed * tickSpacing;
    }

    function _estimateFees(Ticks memory _ticks, int24 _currentTick)
        internal
        view
        returns (uint256, uint256)
    {
        (
            uint128 liquidity,
            uint256 feeGrowthInside0Last,
            uint256 feeGrowthInside1Last,
            uint128 owed0,
            uint128 owed1
        ) = _rawPosition(_ticks, address(this));
        // Compute current fees earned
        uint256 wantFee =
            _computeFeesEarned(_currentTick, true, feeGrowthInside0Last, _ticks, liquidity) + owed0;
        uint256 wethFee =
            _computeFeesEarned(_currentTick, false, feeGrowthInside1Last, _ticks, liquidity) +
                owed1;
        return (wantFee, wethFee);
    }

    function _position(Ticks memory _ticks)
        internal
        view
        returns (
            uint128 liquidity,
            uint128 owed0,
            uint128 owed1
        )
    {
        (liquidity, , , owed0, owed1) = _rawPosition(_ticks, address(this));
    }

    function _calculateLimitOrder()
        internal
        view
        returns (
            uint128 liquidity,
            Ticks memory _limitTicks,
            LimitOrderStatus order
        )
    {
        (uint256 _wantBalance, uint256 _wethBalance) = _getLimitOrderAmounts();
        (Ticks memory bid, Ticks memory ask) = _getBidAsk();

        uint128 bidLiquidity = _liquidityForAmount0(bid, _wantBalance);
        uint128 askLiquidity = _liquidityForAmount1(ask, _wethBalance);

        if (bidLiquidity > askLiquidity) {
            _limitTicks = bid;
            order = LimitOrderStatus.Bid;
            liquidity = bidLiquidity;
        } else {
            _limitTicks = ask;
            order = LimitOrderStatus.Ask;
            liquidity = askLiquidity;
        }
    }

    function _wethToWant(uint256 _wethAmount, bool _oracle) internal view returns (uint256) {
        if (_wethAmount == 0) return 0;
        (, int24 tick, , , , , ) = uniV3Pool.slot0();
        uint256 price =
            _oracle ? aaveOracle.getAssetPrice(address(wETH)).div(100) : calcTickPrice(tick);
        return price.mul(_wethAmount).div(1e18);
    }

    /**
     * @dev Returns the information about a position by the position's key
     */
    function _getPosition(Ticks memory _ticks) internal view returns (Position memory) {
        (uint128 _liquidity, uint128 owed0, uint128 owed1) = _position(_ticks);

        (uint256 amount0, uint256 amount1) = _amountsForLiquidity(_liquidity, _ticks);
        Position memory pos =
            Position({
                token0: amount0.add(uint256(owed0)),
                token1: amount1.add(uint256(owed1)),
                liquidity: _liquidity
            });
        return pos;
    }

    function _getPositionsTotalAssets() internal view returns (uint256, uint256) {
        (Position memory basePos, Position memory limitPos) = _openPositions();
        return (basePos.token0.add(limitPos.token0), basePos.token1.add(limitPos.token1));
    }

    /**
     * @dev When ETH goes down the Tick goes up.
     *  Ask:
     *       - Ticks set under the current Tick.
     *       - To swap ETH to Want
     *  Bid:
     *       - Ticks set over the current Tick.
     *       - To swap Want to ETH
     *
     */
    function _getBidAsk() internal view returns (Ticks memory bid, Ticks memory ask) {
        (, int24 tick, , , , , ) = uniV3Pool.slot0();
        // NOTE The higher the tick the lower the price of wETH
        int24 tickFloor = _floor(tick);
        int24 tickCeil = tickFloor + tickSpacing;

        bid = Ticks({lowerTick: tickCeil, upperTick: tickCeil + tickSpacing});
        ask = Ticks({lowerTick: tickFloor - tickSpacing, upperTick: tickFloor});
    }

    function _getInitialTicks() internal view returns (Ticks memory) {
        (, int24 tick, , , , , ) = uniV3Pool.slot0();
        int24 tickFloor = _floor(tick);
        int24 tickCeil = tickFloor + tickSpacing;
        return Ticks({lowerTick: tickFloor - tickWidth, upperTick: tickCeil + tickWidth});
    }

    function _calcLiquidityToBurn(uint256 _amountNeeded) internal view returns (uint128) {
        Position memory base = _getPosition(baseTicks);
        uint128 _principalLiquidity = base.liquidity;
        if (_principalLiquidity == 0) return 0;

        uint256 fraction = _amountNeeded.mul(1e18).div(_calcPrincipalInWant());

        uint256 _liquidityNeeded = uint256(_principalLiquidity).mul(fraction).div(1e18);

        return uint128(Math.min(_liquidityNeeded, _principalLiquidity));

        // Remove our specified liquidity amount & Collect fees on the way
    }

    function _setTickParams(int24 _newBaseLowerTick, int24 _newBaseUpperTick) internal {
        baseTicks.lowerTick = _newBaseLowerTick;
        baseTicks.upperTick = _newBaseUpperTick;
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                       Setters                                             //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function setStrategy(address _strategy) external onlyAuthorized {
        strategy = IStrategy(_strategy);
    }

    function setLendHelper(address _lendHelper) external onlyAuthorized {
        lendHelper = ILendingHelper(_lendHelper);
    }

    /**
     * note Sets Tick Params without rebalancing, needed to initialize position.
     */
    function setTickParams(int24 _lowerTick, int24 _upperTick) external onlyAuthorized {
        _setTickParams(_lowerTick, _upperTick);
    }

    function setTickWidth(
        int24 _tickWidth,
        int24 _maxTickDeviation,
        int24 _maxLOTickDeviation
    ) external onlyAuthorized {
        tickWidth = _tickWidth;
        tickRebalanceDeviation = _maxTickDeviation;
        tickLORebalanceDeviation = _maxLOTickDeviation;
    }

    function setDust(uint256 _wantDust, uint256 _wethDust) external onlyAuthorized {
        wantDust = _wantDust;
        wethDust = _wethDust;
    }

    function setLimitOrderMaxSize(uint16 _limitOrderMaxSize) external onlyAuthorized {
        limitOrderMaxSize = _limitOrderMaxSize;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 *
	 * - Addition cannot overflow.
	 */
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, 'SafeMath: addition overflow');

		return c;
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return sub(a, b, 'SafeMath: subtraction overflow');
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 *
	 * - Multiplication cannot overflow.
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, 'SafeMath: multiplication overflow');

		return c;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(a, b, 'SafeMath: division by zero');
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return mod(a, b, 'SafeMath: modulo by zero');
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts with custom message when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

import { SafeMath } from './SafeMath.sol';
import { Address } from './Address.sol';
import { IERC20 } from '../../interfaces/IERC20.sol';

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
	using SafeMath for uint256;
	using Address for address;

	function safeTransfer(
		IERC20 token,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
	}

	function safeTransferFrom(
		IERC20 token,
		address from,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
	}

	/**
	 * @dev Deprecated. This function has issues similar to the ones found in
	 * {IERC20-approve}, and its usage is discouraged.
	 *
	 * Whenever possible, use {safeIncreaseAllowance} and
	 * {safeDecreaseAllowance} instead.
	 */
	function safeApprove(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		// safeApprove should only be called when setting an initial allowance,
		// or when resetting it to zero. To increase and decrease it, use
		// 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
		// solhint-disable-next-line max-line-length
		require(
			(value == 0) || (token.allowance(address(this), spender) == 0),
			'SafeERC20: approve from non-zero to non-zero allowance'
		);
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
	}

	function safeIncreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		uint256 newAllowance = token.allowance(address(this), spender).add(value);
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
	}

	function safeDecreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		uint256 newAllowance =
			token.allowance(address(this), spender).sub(value, 'SafeERC20: decreased allowance below zero');
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
	}

	/**
	 * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
	 * on the return value: the return value is optional (but if data is returned, it must not be false).
	 * @param token The token targeted by the call.
	 * @param data The call data (encoded using abi.encode or one of its variants).
	 */
	function _callOptionalReturn(IERC20 token, bytes memory data) private {
		// We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
		// we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
		// the target address contains contract code and also asserts for success in the low-level call.

		bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
		if (returndata.length > 0) {
			// Return data is optional
			// solhint-disable-next-line max-line-length
			require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
		}
	}
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
	/**
	 * @dev Returns true if `account` is a contract.
	 *
	 * [IMPORTANT]
	 * ====
	 * It is unsafe to assume that an address for which this function returns
	 * false is an externally-owned account (EOA) and not a contract.
	 *
	 * Among others, `isContract` will return false for the following
	 * types of addresses:
	 *
	 *  - an externally-owned account
	 *  - a contract in construction
	 *  - an address where a contract will be created
	 *  - an address where a contract lived, but was destroyed
	 * ====
	 */
	function isContract(address account) internal view returns (bool) {
		// According to EIP-1052, 0x0 is the value returned for not-yet created accounts
		// and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
		// for accounts without code, i.e. `keccak256('')`
		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			codehash := extcodehash(account)
		}
		return (codehash != accountHash && codehash != 0x0);
	}

	/**
	 * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
	 * `recipient`, forwarding all available gas and reverting on errors.
	 *
	 * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
	 * of certain opcodes, possibly making contracts go over the 2300 gas limit
	 * imposed by `transfer`, making them unable to receive funds via
	 * `transfer`. {sendValue} removes this limitation.
	 *
	 * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
	 *
	 * IMPORTANT: because control is transferred to `recipient`, care must be
	 * taken to not create reentrancy vulnerabilities. Consider using
	 * {ReentrancyGuard} or the
	 * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
	 */
	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, 'Address: insufficient balance');

		// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = recipient.call{ value: amount }('');
		require(success, 'Address: unable to send value, recipient may have reverted');
	}

	/**
	 * @dev Performs a Solidity function call using a low level `call`. A
	 * plain`call` is an unsafe replacement for a function call: use this
	 * function instead.
	 *
	 * If `target` reverts with a revert reason, it is bubbled up by this
	 * function (like regular Solidity function calls).
	 *
	 * Returns the raw returned data. To convert to the expected return value,
	 * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
	 *
	 * Requirements:
	 *
	 * - `target` must be a contract.
	 * - calling `target` with `data` must not revert.
	 *
	 * _Available since v3.1._
	 */
	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCall(target, data, 'Address: low-level call failed');
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
	 * `errorMessage` as a fallback revert reason when `target` reverts.
	 *
	 * _Available since v3.1._
	 */
	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return _functionCallWithValue(target, data, 0, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but also transferring `value` wei to `target`.
	 *
	 * Requirements:
	 *
	 * - the calling contract must have an ETH balance of at least `value`.
	 * - the called Solidity function must be `payable`.
	 *
	 * _Available since v3.1._
	 */
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
	}

	/**
	 * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
	 * with `errorMessage` as a fallback revert reason when `target` reverts.
	 *
	 * _Available since v3.1._
	 */
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(address(this).balance >= value, 'Address: insufficient balance for call');
		return _functionCallWithValue(target, data, value, errorMessage);
	}

	function _functionCallWithValue(
		address target,
		bytes memory data,
		uint256 weiValue,
		string memory errorMessage
	) private returns (bytes memory) {
		require(isContract(target), 'Address: call to non-contract');

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
		if (success) {
			return returndata;
		} else {
			// Look for revert reason and bubble it up if present
			if (returndata.length > 0) {
				// The easiest way to bubble the revert reason is using memory via assembly

				// solhint-disable-next-line no-inline-assembly
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
	/**
	 * @dev Returns the largest of two numbers.
	 */
	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a >= b ? a : b;
	}

	/**
	 * @dev Returns the smallest of two numbers.
	 */
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	/**
	 * @dev Returns the average of two numbers. The result is rounded towards
	 * zero.
	 */
	function average(uint256 a, uint256 b) internal pure returns (uint256) {
		// (a + b) / 2 can overflow, so we distribute
		return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio =
            absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
            ? tickHi
            : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

import './FullMath.sol';
import './FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: MIT

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the preconditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

pragma experimental ABIEncoderV2;

import { IERC20 } from './IERC20.sol';

struct StrategyParams {
	uint256 performanceFee;
	uint256 activation;
	uint256 debtRatio;
	uint256 minDebtPerHarvest;
	uint256 maxDebtPerHarvest;
	uint256 lastReport;
	uint256 totalDebt;
	uint256 totalGain;
	uint256 totalLoss;
}

interface VaultAPI is IERC20 {
	function name() external view returns (string calldata);

	function symbol() external view returns (string calldata);

	function decimals() external view returns (uint256);

	function apiVersion() external pure returns (string memory);

	function permit(
		address owner,
		address spender,
		uint256 amount,
		uint256 expiry,
		bytes calldata signature
	) external returns (bool);

	// NOTE: Vyper produces multiple signatures for a given function with "default" args
	function deposit() external returns (uint256);

	function deposit(uint256 amount) external returns (uint256);

	function deposit(uint256 amount, address recipient) external returns (uint256);

	// NOTE: Vyper produces multiple signatures for a given function with "default" args
	function withdraw() external returns (uint256);

	function withdraw(uint256 maxShares) external returns (uint256);

	function withdraw(uint256 maxShares, address recipient) external returns (uint256);

	function token() external view returns (address);

	function strategies(address _strategy) external view returns (StrategyParams memory);

	function pricePerShare() external view returns (uint256);

	function totalAssets() external view returns (uint256);

	function depositLimit() external view returns (uint256);

	function maxAvailableShares() external view returns (uint256);

	/**
	 * View how much the Vault would increase this Strategy's borrow limit,
	 * based on its present performance (since its last report). Can be used to
	 * determine expectedReturn in your Strategy.
	 */
	function creditAvailable() external view returns (uint256);

	/**
	 * View how much the Vault would like to pull back from the Strategy,
	 * based on its present performance (since its last report). Can be used to
	 * determine expectedReturn in your Strategy.
	 */
	function debtOutstanding() external view returns (uint256);

	/**
	 * View how much the Vault expect this Strategy to return at the current
	 * block, based on its present performance (since its last report). Can be
	 * used to determine expectedReturn in your Strategy.
	 */
	function expectedReturn() external view returns (uint256);

	/**
	 * This is the main contact point where the Strategy interacts with the
	 * Vault. It is critical that this call is handled as intended by the
	 * Strategy. Therefore, this function will be called by BaseStrategy to
	 * make sure the integration is correct.
	 */
	function report(
		uint256 _gain,
		uint256 _loss,
		uint256 _debtPayment
	) external returns (uint256);

	/**
	 * This function should only be used in the scenario where the Strategy is
	 * being retired but no migration of the positions are possible, or in the
	 * extreme scenario that the Strategy needs to be put into "Emergency Exit"
	 * mode in order for it to exit as quickly as possible. The latter scenario
	 * could be for any reason that is considered "critical" that the Strategy
	 * exits its position as fast as possible, such as a sudden change in
	 * market conditions leading to losses, or an imminent failure in an
	 * external dependency.
	 */
	function revokeStrategy() external;

	/**
	 * View the governance address of the Vault to assert privileged functions
	 * can only be called by governance. The Strategy serves the Vault, so it
	 * is subject to governance defined by the Vault.
	 */
	function governance() external view returns (address);

	/**
	 * View the management address of the Vault to assert privileged functions
	 * can only be called by management. The Strategy serves the Vault, so it
	 * is subject to management defined by the Vault.
	 */
	function management() external view returns (address);

	/**
	 * View the guardian address of the Vault to assert privileged functions
	 * can only be called by guardian. The Strategy serves the Vault, so it
	 * is subject to guardian defined by the Vault.
	 */
	function guardian() external view returns (address);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma experimental ABIEncoderV2;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniV3 {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );

    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;

interface IStrategy {
    function balanceOfWant() external view returns (uint256);

    function balanceOfWeth() external view returns (uint256);

    function wantDust() external view returns (uint256);

    function wethDust() external view returns (uint256);

    function wethToWant(uint256 _wethAmount, bool _oracle) external view returns (uint256);

    function wantToWeth(uint256 _wantAmount, bool _oracle) external view returns (uint256);

    function estimatedTotalAssetsSafe() external view returns (uint256);

    function balanceOfWethInWantOracle() external view returns (uint256);

    function balanceOfWethInWant() external view returns (uint256);

    function swapToWeth(uint256 _amountIn) external;

    function getTotalInvestedAssets() external view returns (uint256, uint256);

    function strategyDebt() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

interface ILendingHelper {
    function getCollatRatios(address token)
        external
        view
        returns (uint256 ltv, uint256 liquidationThreshold);

    function netPositionInWant() external view returns (uint256);

    function triggerLend() external view returns (bool);

    function balanceLending() external;

    function adjustToTargetRatio() external;

    function liquidateAllLend() external returns (uint256 _amountFree);

    function freeFunds(uint256 amountToFree) external returns (uint256 _wantAvailable);

    function unwindPosition(uint256 _repayAmount) external;

    function setLendingRatio(uint256 _lendingRatio) external;

    function setDust(uint256 _wantDust, uint256 _wethDust) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0

interface IAaveOracle {
    function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}