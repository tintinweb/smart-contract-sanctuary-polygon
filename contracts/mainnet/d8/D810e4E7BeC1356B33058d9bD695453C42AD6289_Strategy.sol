// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {BaseStrategy} from './BaseStrategy.sol';

import {SafeMath} from './library/SafeMath.sol';
import {SafeERC20} from './library/SafeERC20.sol';
import {Address} from './library/Address.sol';
import {ERC20} from './library/ERC20.sol';
import {Math} from './library/Math.sol';
import {TickMath} from './library/TickMath.sol';
import {FullMath} from './library/FullMath.sol';
import {LiquidityAmounts} from './library/LiquidityAmounts.sol';

import {IERC20} from '../interfaces/IERC20.sol';
import {IUniV3} from '../interfaces/IUniV3.sol';
import {IAaveOracle} from '../interfaces/IAaveOracle.sol';

import {IUniswapV3MintCallback} from '../interfaces/IUniswapV3MintCallback.sol';
import {IUniswapV3SwapCallback} from '../interfaces/IUniswapV3SwapCallback.sol';

/**
 * @title Epsylon Uniswap V3 Liquidity Provisioning Strategy.
 * @author Jake Fleming & 0xCross
 * @notice This strategy interacts with the Uniswap-v3 pool contracts directly, like their NFT wrapper does.
 *
 * @dev    _tickLower, _tickUpper and the stored variables tickLower, tickUpper are essentially the same.
 *         We need to read the different variables from storage and just pass them as arguments to the functions.
 *         This is just a way to save on gas. Reading from storage is more expensive than reading from memory.
 */

struct Ticks {
    int24 lowerTick;
    int24 upperTick;
}

struct Position {
    uint256 token0;
    uint256 token1;
    uint128 liquidity;
}

contract Strategy is BaseStrategy, IUniswapV3MintCallback, IUniswapV3SwapCallback {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Constants
    uint256 internal constant basisOne = 10000;

    // These are variables specific to our want-ETH pair
    IUniV3 public constant uniV3Pool = IUniV3(0x45dDa9cb7c25131DF268515131f647d726f50608);
    IAaveOracle public constant aaveOracle =
        IAaveOracle(0xb023e699F5a33916Ea823A16485e259257cA8Bd1);

    IERC20 public wETH = IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);

    Ticks public limitTicks;
    int24 public tickSpacing;
    int24 public tickWidth = 0;
    int24 public tickRebalanceDeviation = 20;
    uint256 public uniPoolFee = 5;

    // Uniswap Mint Callback
    bool internal mintStorage;
    bool internal swapStorage;

    // In bps, how much slippage we allow between our optimistic assets and real. 50 = 0.5% slippage
    uint256 public slippageMax = 50;

    // Only set this to true externally when we want to trigger our keepers to harvest for us
    uint256 public wantDust = 1e4;
    uint256 public wethDust = 1e12;

    address public stupidRobot;

    event LimitOrderSet(int24 tick, int24 newTickLower, int24 newTickUpper);

    constructor(address _vault) public BaseStrategy(_vault) {
        tickSpacing = uniV3Pool.tickSpacing();
        // NOTE Pool's fee in hundredths of a bip, i.e. 500
        uniPoolFee = uint256(uniV3Pool.fee()).div(100);
    }

    modifier onlyStupidRobot() {
        require(msg.sender == stupidRobot || msg.sender == governance());
        _;
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                Public View func                                           //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function name() external view override returns (string memory) {
        return 'Strategy Max Concentration Uniswap V3 USDC-wETH';
    }

    /**
     * @notice Assume real value; the only place this is directly used is when liquidating the whole strat.
     */
    function estimatedTotalAssets() public view override returns (uint256) {
        return balanceOfWant().add(balanceOfWethInWant()).add(positionBalance());
    }

    /**
     * @notice Here we use Oracles to calculate the price of ETH, since this function is used for slippage.
     *         We don't want to miss-calculate the before and after.
     */
    function estimatedTotalAssetsOracle() public view returns (uint256) {
        return balanceOfWant().add(balanceOfWethInWantOracle()).add(positionBalanceOracle());
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfWeth() public view returns (uint256) {
        return wETH.balanceOf(address(this));
    }

    function balanceOfWethInWant() public view returns (uint256) {
        return wethToWant(balanceOfWeth(), false);
    }

    function balanceOfWethInWantOracle() public view returns (uint256) {
        return wethToWant(balanceOfWeth(), true);
    }

    function wethToWant(uint256 _wethAmount, bool _oracle) public view returns (uint256) {
        if (_wethAmount == 0) return 0;
        return _wethPrice(_oracle).mul(_wethAmount).div(1e18);
    }

    function wantToWeth(uint256 _wantAmount, bool _oracle) public view returns (uint256) {
        if (_wantAmount == 0) return 0;
        return _wantAmount.mul(1e18).div(_wethPrice(_oracle));
    }

    function getCurrentWethPrice() public view returns (uint256) {
        return getTickPrice(currentTick());
    }

    function getOracleWethPrice() public view returns (uint256) {
        return aaveOracle.getAssetPrice(address(wETH)).div(100);
    }

    function currentTick() public view returns (int24 tick) {
        (, tick, , , , , ) = uniV3Pool.slot0();
    }

    function getTickPrice(int24 _tick) public pure returns (uint256) {
        uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(_tick);
        return uint256(2**192).mul(1e18).div(uint256(sqrtPrice).mul(uint256(sqrtPrice)));
    }

    /**
     * @dev returns balance of our UniV3 LO, factoring Uniswap swap fee.
     */
    function positionBalance() public view returns (uint256) {
        return _getBalance(basisOne.sub(uniPoolFee), false);
    }

    /**
     * @dev Returns balance of our UniV3 LO, swapping all Weth to want using Aave oracles.
     */
    function positionBalanceOracle() public view returns (uint256) {
        return _getBalance(basisOne, true);
    }

    function limitOrderPosition()
        public
        view
        returns (
            uint256,
            uint256,
            uint128
        )
    {
        return _getPosition(limitTicks);
    }

    function estimatedImpermanentLoss() public view returns (uint256) {
        uint256 debt = strategyDebt();
        uint256 currentBalance = estimatedTotalAssets();
        if (currentBalance > debt) return 0;
        return debt.sub(currentBalance);
    }

    function estimateLimitOrderFees() public view returns (uint256) {
        (, int24 tick, , , , , ) = uniV3Pool.slot0();
        (uint256 wantFee, uint256 wethFee) = _estimateFees(limitTicks, tick);
        // Compute current fees earned
        return wantFee.add(wethToWant(wethFee, false));
    }

    function estimatedHarvest() public view returns (int256) {
        return int256(estimateLimitOrderFees() - estimatedImpermanentLoss());
    }

    function strategyDebt() public view returns (uint256) {
        return vault.strategies(address(this)).totalDebt;
    }

    function rebalanceTrigger() public view returns (bool) {
        int24 tick = currentTick();
        if (tick > limitTicks.lowerTick && tick > limitTicks.upperTick + tickRebalanceDeviation)
            return true;
        if (tick < limitTicks.upperTick && tick < limitTicks.lowerTick - tickRebalanceDeviation)
            return true;
        return false;
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                           Accounting/Investing func                                       //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        if (_debtOutstanding > 0) {
            (_debtPayment, _loss) = liquidatePosition(_debtOutstanding);
        }

        uint256 initialWantBalance = balanceOfWant();

        (, uint256 wethFees) = _collectTradingFees();

        // Convert all of our wETH profits to USDC for ease of accounting
        if (wethFees > wethDust) {
            _swapToWant(wethFees);
        }

        uint256 debt = vault.strategies(address(this)).totalDebt;
        uint256 currentBalance = estimatedTotalAssets();
        uint256 wantBalance = balanceOfWant();

        // TODO: rethink how to distribute the profits
        if (currentBalance > debt) {
            if (wantBalance > initialWantBalance) {
                _profit = wantBalance.sub(initialWantBalance);
            }
            _loss = 0;
            if (wantBalance < _profit) {
                _profit = wantBalance;
                _debtPayment = 0;
            } else if (wantBalance > _profit.add(_debtOutstanding)) {
                _debtPayment = _debtOutstanding;
            } else {
                _debtPayment = wantBalance.sub(_profit);
            }
        } else {
            _loss = debt.sub(currentBalance);
            _debtPayment = Math.min(wantBalance, _debtOutstanding);
        }
    }

    function adjustPosition(uint256) internal override {
        _collectTradingFees(); // Just collect trading fees accrued
    }

    function _renewLimitOrder() internal {
        _enforceSlippage(getOracleWethPrice(), getCurrentWethPrice(), slippageMax); // Check pool health
        uint256 initialETA = estimatedTotalAssetsOracle();
        _unwindPosition(limitTicks);
        _setLimitOrder();
        _enforceSlippage(initialETA, estimatedTotalAssetsOracle(), slippageMax);
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                               Internal Core func                                          //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    /**
     * NOTE This is only called externally by user withdrawals.
     */
    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        if (_amountNeeded > estimatedTotalAssets()) {
            _liquidatedAmount = liquidateAllPositions();
            _loss = _amountNeeded > _liquidatedAmount ? _amountNeeded.sub(_liquidatedAmount) : 0;
            return (_liquidatedAmount, _loss);
        }
        // Check if we have enough free funds to cover the withdrawal
        uint256 wantBal = balanceOfWant();
        if (wantBal < _amountNeeded) {
            // We need to close some positions to get more Want
            _withdrawSome(_amountNeeded);
            // Recalculate balance of Want after closing positions
            wantBal = balanceOfWant();
        }
        // Check again if we have enough balance available to cover the liquidation
        if (wantBal >= _amountNeeded) {
            _liquidatedAmount = _amountNeeded;
        } else {
            // We took a loss
            _liquidatedAmount = wantBal;
            _loss = _amountNeeded.sub(wantBal);
        }
    }

    function liquidateAllPositions() internal override returns (uint256) {
        uint256 etaBefore = estimatedTotalAssetsOracle();
        // We remove the liquidity from Limit Order position
        _unwindPosition(limitTicks);
        if (balanceOfWeth() > wethDust) {
            _swapToWant(balanceOfWeth());
        }
        // Check that all the ETA has been converted to Want correctly
        _enforceSlippage(etaBefore, balanceOfWant(), slippageMax);
        return balanceOfWant();
    }

    /**
     * @dev Withdraw some want from the vaults, probably don't want to allow users to initiate this
     *      1 -> Convert wETH that is loose to USDC.
     *      2 -> Withdraw funds from Limit Order Position.
     */
    function _withdrawSome(uint256 _initialWantNeeded) internal {
        // ------------- 1  ------------- //
        uint256 looseWant = balanceOfWant();
        if (_initialWantNeeded > looseWant) {
            _swapNeededWeth(_initialWantNeeded.sub(looseWant));
        }

        // ------------- 2  ------------- //
        uint256 amountNeeded = _calcAmountNeeded(_initialWantNeeded);
        if (amountNeeded > 0) {
            _withdrawFromLimitOrder(amountNeeded);
        }
    }

    function _withdrawFromLimitOrder(uint256 amountNeeded) internal {
        (, , uint128 _liquidity) = limitOrderPosition();
        if (_liquidity > 0) {
            uint256 fraction = amountNeeded.mul(1e18).div(_getBalance(basisOne, false));

            uint256 _liquidityNeeded = uint256(_liquidity).mul(fraction).div(1e18);

            uint128 liquidityToBurn = uint128(Math.min(_liquidityNeeded, _liquidity));

            // Remove our specified liquidity amount & collect fees on the way
            _burnAndCollectLiquidity(liquidityToBurn, limitTicks);

            // Swap any weth we have to USDC
            if (balanceOfWeth() > 0) {
                _swapToWant(balanceOfWeth());
            }
        }
    }

    function _swapNeededWeth(uint256 _wantNeeded) internal {
        if (_wantNeeded > 0) {
            uint256 wethToSell = Math.min(wantToWeth(_wantNeeded, false), balanceOfWeth());
            if (wethToSell > wethDust) _swapToWant(wethToSell);
        }
    }

    function _calcAmountNeeded(uint256 _amountNeeded) internal view returns (uint256) {
        return _amountNeeded > balanceOfWant() ? _amountNeeded.sub(balanceOfWant()) : 0;
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                    Swap  func                                             //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function _swapToWant(uint256 _amountIn) internal {
        uint256 wantBalBefore = balanceOfWant();
        _swap(int256(_amountIn), false);
        _enforceSlippage(
            wethToWant(_amountIn, true),
            balanceOfWant().sub(wantBalBefore),
            slippageMax
        );
    }

    function _swap(int256 _amountIn, bool _in) internal returns (int256, int256) {
        (uint160 sqrtPriceX96, , , , , , ) = uniV3Pool.slot0();
        uint256 slippage = _in ? basisOne.sub(slippageMax) : basisOne.add(slippageMax);
        swapStorage = true;
        return
            uniV3Pool.swap(
                address(this),
                _in, // Swap direction, true:  token0 -> token1, false: token1 -> token0
                _amountIn, // amountSpecified: The amount of the swap
                uint160(uint256(sqrtPriceX96).mul(slippage).div(basisOne)), // sqrtPriceLimitX96: The price cannot be less than this
                abi.encode(0) // data
            );
    }

    function _enforceSlippage(
        uint256 _intended,
        uint256 _actual,
        uint256 _slippage
    ) internal pure {
        uint256 exitSlipped = _intended > _actual ? _intended.sub(_actual) : 0;
        require(exitSlipped <= _intended.mul(_slippage).div(basisOne), 'Slipped!');
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                      Uni V3 func                                          //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function _unwindPosition(Ticks memory _tick) internal returns (uint256, uint256) {
        (uint128 _liquidityLO, , ) = _position(_tick);

        if (_liquidityLO > 0) {
            return _burnAndCollectLiquidity(_liquidityLO, _tick);
        }
    }

    /**
     * @dev When ETH goes down the Tick goes up.
     *  Ask:
     *       - Ticks set under the current Tick.
     *       - To swap ETH to Want
     *  Bid:
     *       - Ticks set over the current Tick.
     *       - To swap Want to ETH
     */
    function _getBidAsk() internal view returns (Ticks memory bid, Ticks memory ask) {
        // The higher the tick the lower the price of wETH
        int24 tickFloor = _floor(currentTick());
        int24 tickCeil = tickFloor + tickSpacing;

        bid = Ticks({lowerTick: tickCeil, upperTick: tickCeil + tickSpacing + tickWidth});
        ask = Ticks({lowerTick: tickFloor - tickSpacing - tickWidth, upperTick: tickFloor});
    }

    function _setLimitOrder() internal {
        (Ticks memory bid, Ticks memory ask) = _getBidAsk();

        uint128 bidLiquidity = _liquidityForAmount0(bid, balanceOfWant());
        uint128 askLiquidity = _liquidityForAmount1(ask, balanceOfWeth());

        if (bidLiquidity > askLiquidity) {
            _mintLiquidity(bidLiquidity, bid);
            limitTicks = bid;
            emit LimitOrderSet(currentTick(), bid.lowerTick, bid.upperTick);
        } else {
            _mintLiquidity(askLiquidity, ask);
            limitTicks = ask;
            emit LimitOrderSet(currentTick(), ask.lowerTick, ask.upperTick);
        }
    }

    /**
     * note Deposits liquidity in a range on the Uniswap pool.
     *      Mints liquidity for the desired position.
     * @dev amounts of tokens received from Uniswap Pool functions might be manipulated by front runners
     *      amount0Min & amount1Min mandatory
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

    /**
     * @dev Collects tokens owed to a position from accumulated swap fees or burned liquidity.
     */
    function _collectTradingFees() internal returns (uint256 fee0, uint256 fee1) {
        (uint128 _liquidityL, , ) = _position(limitTicks);
        if (_liquidityL > 0) {
            return _burnAndCollectLiquidity(0, limitTicks);
        }
    }

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
     * @dev Get the amounts of the given numbers of liquidity tokens.
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
        Ticks memory _tick,
        uint128 _liquidity
    ) internal view returns (uint256 fee) {
        uint256 feeGrowthOutsideLower;
        uint256 feeGrowthOutsideUpper;
        uint256 feeGrowthGlobal;
        if (_isZero) {
            feeGrowthGlobal = uniV3Pool.feeGrowthGlobal0X128();
            (, , feeGrowthOutsideLower, , , , , ) = uniV3Pool.ticks(_tick.lowerTick);
            (, , feeGrowthOutsideUpper, , , , , ) = uniV3Pool.ticks(_tick.upperTick);
        } else {
            feeGrowthGlobal = uniV3Pool.feeGrowthGlobal1X128();
            (, , , feeGrowthOutsideLower, , , , ) = uniV3Pool.ticks(_tick.lowerTick);
            (, , , feeGrowthOutsideUpper, , , , ) = uniV3Pool.ticks(_tick.upperTick);
        }

        // Calculate fee growth below
        uint256 feeGrowthBelow;
        if (_currentTick >= _tick.lowerTick) {
            feeGrowthBelow = feeGrowthOutsideLower;
        } else {
            feeGrowthBelow = feeGrowthGlobal - feeGrowthOutsideLower;
        }

        // Calculate fee growth above
        uint256 feeGrowthAbove;
        if (_currentTick < _tick.upperTick) {
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

    /**
     * @dev Returns the information about a position by the position's key.
     */
    function _getPosition(Ticks memory _ticks)
        internal
        view
        returns (
            uint256 usdcAmount,
            uint256 wethAmount,
            uint128 liquidity
        )
    {
        (uint128 _liquidity, uint128 owed0, uint128 owed1) = _position(_ticks);

        (uint256 amount0, uint256 amount1) = _amountsForLiquidity(_liquidity, _ticks);

        // Computed amount of token0 owed to the position
        usdcAmount = amount0.add(uint256(owed0));
        // Computed amount of token1 owed to the position
        wethAmount = amount1.add(uint256(owed1));
        liquidity = _liquidity;
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

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                    Uni Callback functions                                 //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    /**
     * @dev Callback function of uniswapV3Pool mint
     *      (Uniswap uses a callback pattern to pull funds from the caller)
     *      Access restricted only for the pool address(uniV3Pool)
     *      Bool storage mintStorage, needed in case Uniswap were hacked
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
        if (amount0Owed > 0) want.safeTransfer(address(uniV3Pool), amount0Owed);
        if (amount1Owed > 0) wETH.safeTransfer(address(uniV3Pool), amount1Owed);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external override {
        require(msg.sender == address(uniV3Pool));
        // Boolean storage variable to track that the callback was preceded by a call to poolSwap
        require(swapStorage == true);
        swapStorage = false;
        if (amount0Delta > 0) want.safeTransfer(address(uniV3Pool), uint256(amount0Delta));
        if (amount1Delta > 0) wETH.safeTransfer(address(uniV3Pool), uint256(amount1Delta));
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                     Internal Helper func                                  //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function _getBalance(uint256 _fees, bool _oracle) internal view returns (uint256) {
        (uint256 totalUsdcBalance, uint256 totalWethBalance, ) = limitOrderPosition();
        if (totalWethBalance == 0) return totalUsdcBalance;
        uint256 wethInUsdc = wethToWant(totalWethBalance, _oracle);
        uint256 wethInUsdcMinusFees = wethInUsdc.mul(_fees).div(basisOne);
        return wethInUsdcMinusFees.add(totalUsdcBalance);
    }

    function _wethPrice(bool _oracle) internal view returns (uint256) {
        return _oracle ? getOracleWethPrice() : getCurrentWethPrice();
    }

    /**
     * @dev Rounds tick down towards negative infinity, so that it's a multiple of `tickSpacing`.
     */
    function _floor(int24 tick) internal view returns (int24) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;
        return compressed * tickSpacing;
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                        Setters                                            //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function setManagerParams(
        uint256 _slippageMax,
        uint256 _uniPoolFee,
        uint256 _wantDust,
        uint256 _wethDust
    ) external onlyVaultManagers {
        slippageMax = _slippageMax;
        uniPoolFee = _uniPoolFee;
        wantDust = _wantDust;
        wethDust = _wethDust;
    }

    function setTickParams(int24 _tickWidth, int24 _maxTickDeviation) external onlyVaultManagers {
        require(_tickWidth % tickSpacing == 0);
        tickWidth = _tickWidth;
        tickRebalanceDeviation = _maxTickDeviation;
    }

    function unwindPositions() external onlyVaultManagers {
        _unwindPosition(limitTicks);
        _swapToWant(balanceOfWeth());
    }

    function setStupidRobot(address _stupidRobot) external onlyVaultManagers {
        stupidRobot = _stupidRobot;
    }

    function renewLimitOrder() external onlyStupidRobot {
        _renewLimitOrder();
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                        Override                                           //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function tendTrigger(uint256 callCostinEth) public view override returns (bool) {}

    function prepareMigration(address _newStrategy) internal override {
        _unwindPosition(limitTicks);
        uint256 wethBalance = balanceOfWeth();
        if (wethBalance > 0) {
            wETH.transfer(_newStrategy, wethBalance); // Sends ETH, want already included in BaseStrategy
        }
    }

    function ethToWant(uint256 _amtInWei) public view override returns (uint256) {}

    function protectedTokens() internal view override returns (address[] memory) {}

    receive() external payable {}
}

pragma experimental ABIEncoderV2;

import { IERC20 } from '../interfaces/IERC20.sol';
import { SafeMath } from './library/SafeMath.sol';
import { SafeERC20 } from './library/SafeERC20.sol';

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
 * This interface is here for the keeper bot to use.
 */
interface StrategyAPI {
	function name() external view returns (string memory);

	function vault() external view returns (address);

	function want() external view returns (address);

	function apiVersion() external pure returns (string memory);

	function keeper() external view returns (address);

	function isActive() external view returns (bool);

	function delegatedAssets() external view returns (uint256);

	function estimatedTotalAssets() external view returns (uint256);

	function tendTrigger(uint256 callCost) external view returns (bool);

	function tend() external;

	function harvestTrigger(uint256 callCost) external view returns (bool);

	function harvest() external;

	event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
}

interface HealthCheck {
	function check(
		uint256 profit,
		uint256 loss,
		uint256 debtPayment,
		uint256 debtOutstanding,
		uint256 totalDebt
	) external view returns (bool);
}

/**
 * @title Yearn Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */

abstract contract BaseStrategy {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	string public metadataURI;

	// health checks
	bool public doHealthCheck;
	address public healthCheck;

	/**
	 * @notice
	 *  Used to track which version of `StrategyAPI` this Strategy
	 *  implements.
	 * @dev The Strategy's version must match the Vault's `API_VERSION`.
	 * @return A string which holds the current API version of this contract.
	 */
	function apiVersion() public pure returns (string memory) {
		return '0.4.3';
	}

	/**
	 * @notice This Strategy's name.
	 * @dev
	 *  You can use this field to manage the "version" of this Strategy, e.g.
	 *  `StrategySomethingOrOtherV1`. However, "API Version" is managed by
	 *  `apiVersion()` function above.
	 * @return This Strategy's name.
	 */
	function name() external view virtual returns (string memory);

	/**
	 * @notice
	 *  The amount (priced in want) of the total assets managed by this strategy should not count
	 *  towards Yearn's TVL calculations.
	 * @dev
	 *  You can override this field to set it to a non-zero value if some of the assets of this
	 *  Strategy is somehow delegated inside another part of of Yearn's ecosystem e.g. another Vault.
	 *  Note that this value must be strictly less than or equal to the amount provided by
	 *  `estimatedTotalAssets()` below, as the TVL calc will be total assets minus delegated assets.
	 *  Also note that this value is used to determine the total assets under management by this
	 *  strategy, for the purposes of computing the management fee in `Vault`
	 * @return
	 *  The amount of assets this strategy manages that should not be included in Yearn's Total Value
	 *  Locked (TVL) calculation across it's ecosystem.
	 */
	function delegatedAssets() external view virtual returns (uint256) {
		return 0;
	}

	VaultAPI public vault;
	address public strategist;
	address public rewards;
	address public keeper;

	IERC20 public want;

	// So indexers can keep track of this
	event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

	event UpdatedStrategist(address newStrategist);

	event UpdatedKeeper(address newKeeper);

	event UpdatedRewards(address rewards);

	event UpdatedMinReportDelay(uint256 delay);

	event UpdatedMaxReportDelay(uint256 delay);

	event UpdatedProfitFactor(uint256 profitFactor);

	event UpdatedDebtThreshold(uint256 debtThreshold);

	event EmergencyExitEnabled();

	event UpdatedMetadataURI(string metadataURI);

	// The minimum number of seconds between harvest calls. See
	// `setMinReportDelay()` for more details.
	uint256 public minReportDelay;

	// The maximum number of seconds between harvest calls. See
	// `setMaxReportDelay()` for more details.
	uint256 public maxReportDelay;

	// The minimum multiple that `callCost` must be above the credit/profit to
	// be "justifiable". See `setProfitFactor()` for more details.
	uint256 public profitFactor;

	// Use this to adjust the threshold at which running a debt causes a
	// harvest trigger. See `setDebtThreshold()` for more details.
	uint256 public debtThreshold;

	// See note on `setEmergencyExit()`.
	bool public emergencyExit;

	// modifiers
	modifier onlyAuthorized() {
		require(msg.sender == strategist || msg.sender == governance(), '!authorized');
		_;
	}

	modifier onlyEmergencyAuthorized() {
		require(
			msg.sender == strategist ||
				msg.sender == governance() ||
				msg.sender == vault.guardian() ||
				msg.sender == vault.management(),
			'!authorized'
		);
		_;
	}

	modifier onlyStrategist() {
		require(msg.sender == strategist, '!strategist');
		_;
	}

	modifier onlyGovernance() {
		require(msg.sender == governance(), '!authorized');
		_;
	}

	modifier onlyKeepers() {
		require(
			msg.sender == keeper ||
				msg.sender == strategist ||
				msg.sender == governance() ||
				msg.sender == vault.guardian() ||
				msg.sender == vault.management(),
			'!authorized'
		);
		_;
	}

	modifier onlyVaultManagers() {
		require(msg.sender == vault.management() || msg.sender == governance(), '!authorized');
		_;
	}

	constructor(address _vault) public {
		_initialize(_vault, msg.sender, msg.sender, msg.sender);
	}

	/**
	 * @notice
	 *  Initializes the Strategy, this is called only once, when the
	 *  contract is deployed.
	 * @dev `_vault` should implement `VaultAPI`.
	 * @param _vault The address of the Vault responsible for this Strategy.
	 * @param _strategist The address to assign as `strategist`.
	 * The strategist is able to change the reward address
	 * @param _rewards  The address to use for pulling rewards.
	 * @param _keeper The adddress of the _keeper. _keeper
	 * can harvest and tend a strategy.
	 */
	function _initialize(
		address _vault,
		address _strategist,
		address _rewards,
		address _keeper
	) internal {
		require(address(want) == address(0), 'Strategy already initialized');

		vault = VaultAPI(_vault);
		want = IERC20(vault.token());
		want.safeApprove(_vault, uint256(-1)); // Give Vault unlimited access (might save gas)
		strategist = _strategist;
		rewards = _rewards;
		keeper = _keeper;

		// initialize variables
		minReportDelay = 0;
		maxReportDelay = 86400;
		profitFactor = 100;
		debtThreshold = 0;

		vault.approve(rewards, uint256(-1)); // Allow rewards to be pulled
	}

	function setHealthCheck(address _healthCheck) external onlyVaultManagers {
		healthCheck = _healthCheck;
	}

	function setDoHealthCheck(bool _doHealthCheck) external onlyVaultManagers {
		doHealthCheck = _doHealthCheck;
	}

	/**
	 * @notice
	 *  Used to change `strategist`.
	 *
	 *  This may only be called by governance or the existing strategist.
	 * @param _strategist The new address to assign as `strategist`.
	 */
	function setStrategist(address _strategist) external onlyAuthorized {
		require(_strategist != address(0));
		strategist = _strategist;
		emit UpdatedStrategist(_strategist);
	}

	/**
	 * @notice
	 *  Used to change `keeper`.
	 *
	 *  `keeper` is the only address that may call `tend()` or `harvest()`,
	 *  other than `governance()` or `strategist`. However, unlike
	 *  `governance()` or `strategist`, `keeper` may *only* call `tend()`
	 *  and `harvest()`, and no other authorized functions, following the
	 *  principle of least privilege.
	 *
	 *  This may only be called by governance or the strategist.
	 * @param _keeper The new address to assign as `keeper`.
	 */
	function setKeeper(address _keeper) external onlyAuthorized {
		require(_keeper != address(0));
		keeper = _keeper;
		emit UpdatedKeeper(_keeper);
	}

	/**
	 * @notice
	 *  Used to change `rewards`. EOA or smart contract which has the permission
	 *  to pull rewards from the vault.
	 *
	 *  This may only be called by the strategist.
	 * @param _rewards The address to use for pulling rewards.
	 */
	function setRewards(address _rewards) external onlyStrategist {
		require(_rewards != address(0));
		vault.approve(rewards, 0);
		rewards = _rewards;
		vault.approve(rewards, uint256(-1));
		emit UpdatedRewards(_rewards);
	}

	/**
	 * @notice
	 *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
	 *  of blocks that should pass for `harvest()` to be called.
	 *
	 *  For external keepers (such as the Keep3r network), this is the minimum
	 *  time between jobs to wait. (see `harvestTrigger()`
	 *  for more details.)
	 *
	 *  This may only be called by governance or the strategist.
	 * @param _delay The minimum number of seconds to wait between harvests.
	 */
	function setMinReportDelay(uint256 _delay) external onlyAuthorized {
		minReportDelay = _delay;
		emit UpdatedMinReportDelay(_delay);
	}

	/**
	 * @notice
	 *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
	 *  of blocks that should pass for `harvest()` to be called.
	 *
	 *  For external keepers (such as the Keep3r network), this is the maximum
	 *  time between jobs to wait. (see `harvestTrigger()`
	 *  for more details.)
	 *
	 *  This may only be called by governance or the strategist.
	 * @param _delay The maximum number of seconds to wait between harvests.
	 */
	function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
		maxReportDelay = _delay;
		emit UpdatedMaxReportDelay(_delay);
	}

	/**
	 * @notice
	 *  Used to change `profitFactor`. `profitFactor` is used to determine
	 *  if it's worthwhile to harvest, given gas costs. (See `harvestTrigger()`
	 *  for more details.)
	 *
	 *  This may only be called by governance or the strategist.
	 * @param _profitFactor A ratio to multiply anticipated
	 * `harvest()` gas cost against.
	 */
	function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
		profitFactor = _profitFactor;
		emit UpdatedProfitFactor(_profitFactor);
	}

	/**
	 * @notice
	 *  Sets how far the Strategy can go into loss without a harvest and report
	 *  being required.
	 *
	 *  By default this is 0, meaning any losses would cause a harvest which
	 *  will subsequently report the loss to the Vault for tracking. (See
	 *  `harvestTrigger()` for more details.)
	 *
	 *  This may only be called by governance or the strategist.
	 * @param _debtThreshold How big of a loss this Strategy may carry without
	 * being required to report to the Vault.
	 */
	function setDebtThreshold(uint256 _debtThreshold) external onlyAuthorized {
		debtThreshold = _debtThreshold;
		emit UpdatedDebtThreshold(_debtThreshold);
	}

	/**
	 * @notice
	 *  Used to change `metadataURI`. `metadataURI` is used to store the URI
	 * of the file describing the strategy.
	 *
	 *  This may only be called by governance or the strategist.
	 * @param _metadataURI The URI that describe the strategy.
	 */
	function setMetadataURI(string calldata _metadataURI) external onlyAuthorized {
		metadataURI = _metadataURI;
		emit UpdatedMetadataURI(_metadataURI);
	}

	/**
	 * Resolve governance address from Vault contract, used to make assertions
	 * on protected functions in the Strategy.
	 */
	function governance() internal view returns (address) {
		return vault.governance();
	}

	/**
	 * @notice
	 *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
	 *  to `want` (using the native decimal characteristics of `want`).
	 * @dev
	 *  Care must be taken when working with decimals to assure that the conversion
	 *  is compatible. As an example:
	 *
	 *      given 1e17 wei (0.1 ETH) as input, and want is USDC (6 decimals),
	 *      with USDC/ETH = 1800, this should give back 1800000000 (180 USDC)
	 *
	 * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `want`
	 * @return The amount in `want` of `_amtInEth` converted to `want`
	 **/
	function ethToWant(uint256 _amtInWei) public view virtual returns (uint256);

	/**
	 * @notice
	 *  Provide an accurate estimate for the total amount of assets
	 *  (principle + return) that this Strategy is currently managing,
	 *  denominated in terms of `want` tokens.
	 *
	 *  This total should be "realizable" e.g. the total value that could
	 *  *actually* be obtained from this Strategy if it were to divest its
	 *  entire position based on current on-chain conditions.
	 * @dev
	 *  Care must be taken in using this function, since it relies on external
	 *  systems, which could be manipulated by the attacker to give an inflated
	 *  (or reduced) value produced by this function, based on current on-chain
	 *  conditions (e.g. this function is possible to influence through
	 *  flashloan attacks, oracle manipulations, or other DeFi attack
	 *  mechanisms).
	 *
	 *  It is up to governance to use this function to correctly order this
	 *  Strategy relative to its peers in the withdrawal queue to minimize
	 *  losses for the Vault based on sudden withdrawals. This value should be
	 *  higher than the total debt of the Strategy and higher than its expected
	 *  value to be "safe".
	 * @return The estimated total assets in this Strategy.
	 */
	function estimatedTotalAssets() public view virtual returns (uint256);

	/*
	 * @notice
	 *  Provide an indication of whether this strategy is currently "active"
	 *  in that it is managing an active position, or will manage a position in
	 *  the future. This should correlate to `harvest()` activity, so that Harvest
	 *  events can be tracked externally by indexing agents.
	 * @return True if the strategy is actively managing a position.
	 */
	function isActive() public view returns (bool) {
		return vault.strategies(address(this)).debtRatio > 0 || estimatedTotalAssets() > 0;
	}

	/**
	 * Perform any Strategy unwinding or other calls necessary to capture the
	 * "free return" this Strategy has generated since the last time its core
	 * position(s) were adjusted. Examples include unwrapping extra rewards.
	 * This call is only used during "normal operation" of a Strategy, and
	 * should be optimized to minimize losses as much as possible.
	 *
	 * This method returns any realized profits and/or realized losses
	 * incurred, and should return the total amounts of profits/losses/debt
	 * payments (in `want` tokens) for the Vault's accounting (e.g.
	 * `want.balanceOf(this) >= _debtPayment + _profit`).
	 *
	 * `_debtOutstanding` will be 0 if the Strategy is not past the configured
	 * debt limit, otherwise its value will be how far past the debt limit
	 * the Strategy is. The Strategy's debt limit is configured in the Vault.
	 *
	 * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
	 *       It is okay for it to be less than `_debtOutstanding`, as that
	 *       should only used as a guide for how much is left to pay back.
	 *       Payments should be made to minimize loss from slippage, debt,
	 *       withdrawal fees, etc.
	 *
	 * See `vault.debtOutstanding()`.
	 */
	function prepareReturn(uint256 _debtOutstanding)
		internal
		virtual
		returns (
			uint256 _profit,
			uint256 _loss,
			uint256 _debtPayment
		);

	/**
	 * Perform any adjustments to the core position(s) of this Strategy given
	 * what change the Vault made in the "investable capital" available to the
	 * Strategy. Note that all "free capital" in the Strategy after the report
	 * was made is available for reinvestment. Also note that this number
	 * could be 0, and you should handle that scenario accordingly.
	 *
	 * See comments regarding `_debtOutstanding` on `prepareReturn()`.
	 */
	function adjustPosition(uint256 _debtOutstanding) internal virtual;

	/**
	 * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
	 * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
	 * This function should return the amount of `want` tokens made available by the
	 * liquidation. If there is a difference between them, `_loss` indicates whether the
	 * difference is due to a realized loss, or if there is some other sitution at play
	 * (e.g. locked funds) where the amount made available is less than what is needed.
	 *
	 * NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
	 */
	function liquidatePosition(uint256 _amountNeeded) internal virtual returns (uint256 _liquidatedAmount, uint256 _loss);

	/**
	 * Liquidate everything and returns the amount that got freed.
	 * This function is used during emergency exit instead of `prepareReturn()` to
	 * liquidate all of the Strategy's positions back to the Vault.
	 */

	function liquidateAllPositions() internal virtual returns (uint256 _amountFreed);

	/**
	 * @notice
	 *  Provide a signal to the keeper that `tend()` should be called. The
	 *  keeper will provide the estimated gas cost that they would pay to call
	 *  `tend()`, and this function should use that estimate to make a
	 *  determination if calling it is "worth it" for the keeper. This is not
	 *  the only consideration into issuing this trigger, for example if the
	 *  position would be negatively affected if `tend()` is not called
	 *  shortly, then this can return `true` even if the keeper might be
	 *  "at a loss" (keepers are always reimbursed by Yearn).
	 * @dev
	 *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
	 *
	 *  This call and `harvestTrigger()` should never return `true` at the same
	 *  time.
	 * @param callCostInWei The keeper's estimated gas cost to call `tend()` (in wei).
	 * @return `true` if `tend()` should be called, `false` otherwise.
	 */
	function tendTrigger(uint256 callCostInWei) public view virtual returns (bool) {
		// We usually don't need tend, but if there are positions that need
		// active maintainence, overriding this function is how you would
		// signal for that.
		// If your implementation uses the cost of the call in want, you can
		// use uint256 callCost = ethToWant(callCostInWei);

		return false;
	}

	/**
	 * @notice
	 *  Adjust the Strategy's position. The purpose of tending isn't to
	 *  realize gains, but to maximize yield by reinvesting any returns.
	 *
	 *  See comments on `adjustPosition()`.
	 *
	 *  This may only be called by governance, the strategist, or the keeper.
	 */
	function tend() external onlyKeepers {
		// Don't take profits with this call, but adjust for better gains
		adjustPosition(vault.debtOutstanding());
	}

	/**
	 * @notice
	 *  Provide a signal to the keeper that `harvest()` should be called. The
	 *  keeper will provide the estimated gas cost that they would pay to call
	 *  `harvest()`, and this function should use that estimate to make a
	 *  determination if calling it is "worth it" for the keeper. This is not
	 *  the only consideration into issuing this trigger, for example if the
	 *  position would be negatively affected if `harvest()` is not called
	 *  shortly, then this can return `true` even if the keeper might be "at a
	 *  loss" (keepers are always reimbursed by Yearn).
	 * @dev
	 *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
	 *
	 *  This call and `tendTrigger` should never return `true` at the
	 *  same time.
	 *
	 *  See `min/maxReportDelay`, `profitFactor`, `debtThreshold` to adjust the
	 *  strategist-controlled parameters that will influence whether this call
	 *  returns `true` or not. These parameters will be used in conjunction
	 *  with the parameters reported to the Vault (see `params`) to determine
	 *  if calling `harvest()` is merited.
	 *
	 *  It is expected that an external system will check `harvestTrigger()`.
	 *  This could be a script run off a desktop or cloud bot (e.g.
	 *  https://github.com/iearn-finance/yearn-vaults/blob/main/scripts/keep.py),
	 *  or via an integration with the Keep3r network (e.g.
	 *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
	 * @param callCostInWei The keeper's estimated gas cost to call `harvest()` (in wei).
	 * @return `true` if `harvest()` should be called, `false` otherwise.
	 */
	function harvestTrigger(uint256 callCostInWei) public view virtual returns (bool) {
		uint256 callCost = ethToWant(callCostInWei);
		StrategyParams memory params = vault.strategies(address(this));

		// Should not trigger if Strategy is not activated
		if (params.activation == 0) return false;

		// Should not trigger if we haven't waited long enough since previous harvest
		if (block.timestamp.sub(params.lastReport) < minReportDelay) return false;

		// Should trigger if hasn't been called in a while
		if (block.timestamp.sub(params.lastReport) >= maxReportDelay) return true;

		// If some amount is owed, pay it back
		// NOTE: Since debt is based on deposits, it makes sense to guard against large
		//       changes to the value from triggering a harvest directly through user
		//       behavior. This should ensure reasonable resistance to manipulation
		//       from user-initiated withdrawals as the outstanding debt fluctuates.
		uint256 outstanding = vault.debtOutstanding();
		if (outstanding > debtThreshold) return true;

		// Check for profits and losses
		uint256 total = estimatedTotalAssets();
		// Trigger if we have a loss to report
		if (total.add(debtThreshold) < params.totalDebt) return true;

		uint256 profit = 0;
		if (total > params.totalDebt) profit = total.sub(params.totalDebt); // We've earned a profit!

		// Otherwise, only trigger if it "makes sense" economically (gas cost
		// is <N% of value moved)
		uint256 credit = vault.creditAvailable();
		return (profitFactor.mul(callCost) < credit.add(profit));
	}

	/**
	 * @notice
	 *  Harvests the Strategy, recognizing any profits or losses and adjusting
	 *  the Strategy's position.
	 *
	 *  In the rare case the Strategy is in emergency shutdown, this will exit
	 *  the Strategy's position.
	 *
	 *  This may only be called by governance, the strategist, or the keeper.
	 * @dev
	 *  When `harvest()` is called, the Strategy reports to the Vault (via
	 *  `vault.report()`), so in some cases `harvest()` must be called in order
	 *  to take in profits, to borrow newly available funds from the Vault, or
	 *  otherwise adjust its position. In other cases `harvest()` must be
	 *  called to report to the Vault on the Strategy's position, especially if
	 *  any losses have occurred.
	 */
	function harvest() external onlyKeepers {
		uint256 profit = 0;
		uint256 loss = 0;
		uint256 debtOutstanding = vault.debtOutstanding();
		uint256 debtPayment = 0;
		if (emergencyExit) {
			// Free up as much capital as possible
			uint256 amountFreed = liquidateAllPositions();
			if (amountFreed < debtOutstanding) {
				loss = debtOutstanding.sub(amountFreed);
			} else if (amountFreed > debtOutstanding) {
				profit = amountFreed.sub(debtOutstanding);
			}
			debtPayment = debtOutstanding.sub(loss);
		} else {
			// Free up returns for Vault to pull
			(profit, loss, debtPayment) = prepareReturn(debtOutstanding);
		}

		// Allow Vault to take up to the "harvested" balance of this contract,
		// which is the amount it has earned since the last time it reported to
		// the Vault.
		uint256 totalDebt = vault.strategies(address(this)).totalDebt;
		debtOutstanding = vault.report(profit, loss, debtPayment);

		// Check if free returns are left, and re-invest them
		adjustPosition(debtOutstanding);

		// call healthCheck contract
		if (doHealthCheck && healthCheck != address(0)) {
			require(HealthCheck(healthCheck).check(profit, loss, debtPayment, debtOutstanding, totalDebt), '!healthcheck');
		} else {
			doHealthCheck = true;
		}

		emit Harvested(profit, loss, debtPayment, debtOutstanding);
	}

	/**
	 * @notice
	 *  Withdraws `_amountNeeded` to `vault`.
	 *
	 *  This may only be called by the Vault.
	 * @param _amountNeeded How much `want` to withdraw.
	 * @return _loss Any realized losses
	 */
	function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
		require(msg.sender == address(vault), '!vault');
		// Liquidate as much as possible to `want`, up to `_amountNeeded`
		uint256 amountFreed;
		(amountFreed, _loss) = liquidatePosition(_amountNeeded);
		// Send it directly back (NOTE: Using `msg.sender` saves some gas here)
		want.safeTransfer(msg.sender, amountFreed);
		// NOTE: Reinvest anything leftover on next `tend`/`harvest`
	}

	/**
	 * Do anything necessary to prepare this Strategy for migration, such as
	 * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
	 * value.
	 */
	function prepareMigration(address _newStrategy) internal virtual;

	/**
	 * @notice
	 *  Transfers all `want` from this Strategy to `_newStrategy`.
	 *
	 *  This may only be called by the Vault.
	 * @dev
	 * The new Strategy's Vault must be the same as this Strategy's Vault.
	 *  The migration process should be carefully performed to make sure all
	 * the assets are migrated to the new address, which should have never
	 * interacted with the vault before.
	 * @param _newStrategy The Strategy to migrate to.
	 */
	function migrate(address _newStrategy) external {
		require(msg.sender == address(vault));
		require(BaseStrategy(_newStrategy).vault() == vault);
		prepareMigration(_newStrategy);
		want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
	}

	/**
	 * @notice
	 *  Activates emergency exit. Once activated, the Strategy will exit its
	 *  position upon the next harvest, depositing all funds into the Vault as
	 *  quickly as is reasonable given on-chain conditions.
	 *
	 *  This may only be called by governance or the strategist.
	 * @dev
	 *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
	 */
	function setEmergencyExit() external onlyEmergencyAuthorized {
		emergencyExit = true;
		vault.revokeStrategy();

		emit EmergencyExitEnabled();
	}

	/**
	 * Override this to add all tokens/tokenized positions this contract
	 * manages on a *persistent* basis (e.g. not just for swapping back to
	 * want ephemerally).
	 *
	 * NOTE: Do *not* include `want`, already included in `sweep` below.
	 *
	 * Example:
	 * ```
	 *    function protectedTokens() internal override view returns (address[] memory) {
	 *      address[] memory protected = new address[](3);
	 *      protected[0] = tokenA;
	 *      protected[1] = tokenB;
	 *      protected[2] = tokenC;
	 *      return protected;
	 *    }
	 * ```
	 */
	function protectedTokens() internal view virtual returns (address[] memory);

	/**
	 * @notice
	 *  Removes tokens from this Strategy that are not the type of tokens
	 *  managed by this Strategy. This may be used in case of accidentally
	 *  sending the wrong kind of token to this Strategy.
	 *
	 *  Tokens will be sent to `governance()`.
	 *
	 *  This will fail if an attempt is made to sweep `want`, or any tokens
	 *  that are protected by this Strategy.
	 *
	 *  This may only be called by governance.
	 * @dev
	 *  Implement `protectedTokens()` to specify any additional tokens that
	 *  should be protected from sweeping in addition to `want`.
	 * @param _token The token to transfer out of this vault.
	 */
	function sweep(address _token) external onlyGovernance {
		require(_token != address(want), '!want');
		require(_token != address(vault), '!shares');

		address[] memory _protectedTokens = protectedTokens();
		for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], '!protected');

		IERC20(_token).safeTransfer(governance(), IERC20(_token).balanceOf(address(this)));
	}
}

abstract contract BaseStrategyInitializable is BaseStrategy {
	bool public isOriginal = true;
	event Cloned(address indexed clone);

	constructor(address _vault) public BaseStrategy(_vault) {}

	function initialize(
		address _vault,
		address _strategist,
		address _rewards,
		address _keeper
	) external virtual {
		_initialize(_vault, _strategist, _rewards, _keeper);
	}

	function clone(address _vault) external returns (address) {
		require(isOriginal, '!clone');
		return this.clone(_vault, msg.sender, msg.sender, msg.sender);
	}

	function clone(
		address _vault,
		address _strategist,
		address _rewards,
		address _keeper
	) external returns (address newStrategy) {
		// Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
		bytes20 addressBytes = bytes20(address(this));

		assembly {
			// EIP-1167 bytecode
			let clone_code := mload(0x40)
			mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
			mstore(add(clone_code, 0x14), addressBytes)
			mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
			newStrategy := create(0, clone_code, 0x37)
		}

		BaseStrategyInitializable(newStrategy).initialize(_vault, _strategist, _rewards, _keeper);

		emit Cloned(newStrategy);
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

import { Context } from './Context.sol';
import { SafeMath } from './SafeMath.sol';
import { Address } from './Address.sol';
import { IERC20 } from '../../interfaces/IERC20.sol';

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */

contract ERC20 is Context, IERC20 {
	using SafeMath for uint256;
	using Address for address;

	mapping(address => uint256) private _balances;

	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;

	string private _name;
	string private _symbol;
	uint8 private _decimals;

	/**
	 * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
	 * a default value of 18.
	 *
	 * To select a different value for {decimals}, use {_setupDecimals}.
	 *
	 * All three of these values are immutable: they can only be set once during
	 * construction.
	 */
	constructor(string memory name, string memory symbol) public {
		_name = name;
		_symbol = symbol;
		_decimals = 18;
	}

	/**
	 * @dev Returns the name of the token.
	 */
	function name() public view returns (string memory) {
		return _name;
	}

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function symbol() public view returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
	 * called.
	 *
	 * NOTE: This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IERC20-balanceOf} and {IERC20-transfer}.
	 */
	function decimals() public view returns (uint8) {
		return _decimals;
	}

	/**
	 * @dev See {IERC20-totalSupply}.
	 */
	function totalSupply() public view override returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev See {IERC20-balanceOf}.
	 */
	function balanceOf(address account) public view override returns (uint256) {
		return _balances[account];
	}

	/**
	 * @dev See {IERC20-transfer}.
	 *
	 * Requirements:
	 *
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	/**
	 * @dev See {IERC20-allowance}.
	 */
	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}

	/**
	 * @dev See {IERC20-approve}.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	/**
	 * @dev See {IERC20-transferFrom}.
	 *
	 * Emits an {Approval} event indicating the updated allowance. This is not
	 * required by the EIP. See the note at the beginning of {ERC20};
	 *
	 * Requirements:
	 * - `sender` and `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 * - the caller must have allowance for ``sender``'s tokens of at least
	 * `amount`.
	 */
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(
			sender,
			_msgSender(),
			_allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
		);
		return true;
	}

	/**
	 * @dev Atomically increases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {IERC20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	/**
	 * @dev Atomically decreases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {IERC20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 * - `spender` must have allowance for the caller of at least
	 * `subtractedValue`.
	 */
	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero')
		);
		return true;
	}

	/**
	 * @dev Moves tokens `amount` from `sender` to `recipient`.
	 *
	 * This is internal function is equivalent to {transfer}, and can be used to
	 * e.g. implement automatic token fees, slashing mechanisms, etc.
	 *
	 * Emits a {Transfer} event.
	 *
	 * Requirements:
	 *
	 * - `sender` cannot be the zero address.
	 * - `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 */
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual {
		require(sender != address(0), 'ERC20: transfer from the zero address');
		require(recipient != address(0), 'ERC20: transfer to the zero address');

		_beforeTokenTransfer(sender, recipient, amount);

		_balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}

	/** @dev Creates `amount` tokens and assigns them to `account`, increasing
	 * the total supply.
	 *
	 * Emits a {Transfer} event with `from` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `to` cannot be the zero address.
	 */
	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), 'ERC20: mint to the zero address');

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	/**
	 * @dev Destroys `amount` tokens from `account`, reducing the
	 * total supply.
	 *
	 * Emits a {Transfer} event with `to` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `account` cannot be the zero address.
	 * - `account` must have at least `amount` tokens.
	 */
	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), 'ERC20: burn from the zero address');

		_beforeTokenTransfer(account, address(0), amount);

		_balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
	 *
	 * This is internal function is equivalent to `approve`, and can be used to
	 * e.g. set automatic allowances for certain subsystems, etc.
	 *
	 * Emits an {Approval} event.
	 *
	 * Requirements:
	 *
	 * - `owner` cannot be the zero address.
	 * - `spender` cannot be the zero address.
	 */
	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal virtual {
		require(owner != address(0), 'ERC20: approve from the zero address');
		require(spender != address(0), 'ERC20: approve to the zero address');

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/**
	 * @dev Sets {decimals} to a value other than the default one of 18.
	 *
	 * WARNING: This function should only be called from the constructor. Most
	 * applications that interact with token contracts will not expect
	 * {decimals} to ever change, and may work incorrectly if it does.
	 */
	function _setupDecimals(uint8 decimals_) internal {
		_decimals = decimals_;
	}

	/**
	 * @dev Hook that is called before any transfer of tokens. This includes
	 * minting and burning.
	 *
	 * Calling conditions:
	 *
	 * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * will be to transferred to `to`.
	 * - when `from` is zero, `amount` tokens will be minted for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
	 * - `from` and `to` are never both zero.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}
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
}

// SPDX-License-Identifier: AGPL-3.0

interface IAaveOracle {
    function getAssetPrice(address asset) external view returns (uint256);
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

// SPDX-License-Identifier: GPL-2.0-or-later

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
	function _msgSender() internal view virtual returns (address payable) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}