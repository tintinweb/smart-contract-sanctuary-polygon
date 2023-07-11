pragma solidity 0.8.19;

import "./concentrated-liquidity/BaseQuickswapV3Strategy.sol";
import "./concentrated-liquidity/BaseDynamicallyHedgedConcentratedLiquidityStrategy.sol";

contract QuickswapV3AaveDynamicStrategy is
    BaseQuickswapV3Strategy,
    BaseDynamicallyHedgedConcentratedLiquidityStrategy
{
    struct ConstructorParams {
        AaveLibrary.Data aave;
        IFarmingCenter farm;
        IFarmingCenter.IncentiveKey farmKey;
        INonfungiblePositionManager positionManager;
        int24 ticksDown;
        int24 ticksUp;
        int24 ticksUntilRebalance;
        int24 rehedgeStep;
        IERC20Metadata asset;
        ChainlinkPriceFeedAggregator pricesOracle;
        AssetConverter assetConverter;
        string name;
        string symbol;
    }

    constructor(ConstructorParams memory params)
        BaseQuickswapV3Strategy(params.farm, params.farmKey, params.positionManager)
        BaseConcentratedLiquidityStrategy(
            params.ticksDown,
            params.ticksUp,
            params.ticksUntilRebalance,
            params.pricesOracle,
            params.assetConverter
        )
        BaseHedgedConcentratedLiquidityStrategy(params.aave)
        BaseDynamicallyHedgedConcentratedLiquidityStrategy(params.rehedgeStep)
        ApyFlowVault(params.asset)
        ERC20(params.name, params.symbol)
    {
        BaseConcentratedLiquidityStrategy._performApprovals();
    }

    function _harvest() internal override(BaseQuickswapV3Strategy, BaseConcentratedLiquidityStrategy) {
        BaseQuickswapV3Strategy._harvest();
    }

    function _totalAssets()
        internal
        view
        virtual
        override(BaseConcentratedLiquidityStrategy, BaseHedgedConcentratedLiquidityStrategy)
        returns (uint256 assets)
    {
        return BaseHedgedConcentratedLiquidityStrategy._totalAssets();
    }

    function _deposit(uint256 assets)
        internal
        virtual
        override(BaseConcentratedLiquidityStrategy, BaseHedgedConcentratedLiquidityStrategy)
    {
        BaseHedgedConcentratedLiquidityStrategy._deposit(assets);
    }

    function _redeem(uint256 shares)
        internal
        virtual
        override(BaseConcentratedLiquidityStrategy, BaseHedgedConcentratedLiquidityStrategy)
        returns (uint256 assets)
    {
        return BaseHedgedConcentratedLiquidityStrategy._redeem(shares);
    }

    function _readdLiquidity()
        internal
        virtual
        override(BaseConcentratedLiquidityStrategy, BaseHedgedConcentratedLiquidityStrategy)
    {
        BaseHedgedConcentratedLiquidityStrategy._readdLiquidity();
    }

    function _mintNewPosition(uint256 amount0, uint256 amount1)
        internal
        virtual
        override(BaseConcentratedLiquidityStrategy, BaseDynamicallyHedgedConcentratedLiquidityStrategy)
    {
        BaseDynamicallyHedgedConcentratedLiquidityStrategy._mintNewPosition(amount0, amount1);
    }
}

pragma solidity 0.8.19;

import "../../libraries/SafeAssetConverter.sol";
import "../../libraries/QuickswapV3Library.sol";
import "./BaseConcentratedLiquidityStrategy.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

abstract contract BaseQuickswapV3Strategy is BaseConcentratedLiquidityStrategy, IERC721Receiver {
    using QuickswapV3Library for QuickswapV3Library.Data;
    using SafeAssetConverter for AssetConverter;

    QuickswapV3Library.Data public quickswap;

    constructor(
        IFarmingCenter farm,
        IFarmingCenter.IncentiveKey memory farmKey,
        INonfungiblePositionManager positionManager
    ) {
        quickswap = QuickswapV3Library.Data({
            farm: farm,
            farmKey: farmKey,
            token0: IAlgebraPool(farmKey.pool).token0(),
            token1: IAlgebraPool(farmKey.pool).token1(),
            positionManager: positionManager,
            pool: IAlgebraPool(farmKey.pool),
            positionTokenId: 0,
            farmTokenId: 0,
            tickSpacing: IAlgebraPool(farmKey.pool).tickSpacing()
        });

        quickswap.performApprovals();
        Utils.approveIfZeroAllowance(address(quickswap.farmKey.rewardToken), address(assetConverter));
        Utils.approveIfZeroAllowance(address(quickswap.farmKey.bonusRewardToken), address(assetConverter));
    }

    function _tickSpacing() internal view override returns (int24) {
        return quickswap.tickSpacing;
    }

    function token0() public view override returns (address) {
        return quickswap.token0;
    }

    function token1() public view override returns (address) {
        return quickswap.token1;
    }

    function _isPositionExists() internal view override returns (bool) {
        return !(quickswap.positionTokenId == 0);
    }

    function _getPoolData() internal view override returns (int24 currentTick, uint160 sqrtPriceX96) {
        return quickswap.getPoolData();
    }

    function _getPositionData() internal view override returns (ConcentratedLiquidityLibrary.PositionData memory) {
        return quickswap.getPositionData();
    }

    function _increaseLiquidity(uint256 amount0, uint256 amount1) internal override {
        quickswap.exitFarming();
        quickswap.increaseLiquidity(amount0, amount1);
        quickswap.enterFarming();
    }

    function _decreaseLiquidity(uint128 liquidity) internal override returns (uint256 amount0, uint256 amount1) {
        quickswap.exitFarming();
        (amount0, amount1) = quickswap.decreaseLiquidity(liquidity);
        quickswap.enterFarming();
    }

    function _mint(int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1) internal override {
        quickswap.mint(tickLower, tickUpper, amount0, amount1);
        quickswap.enterFarming();
    }

    function _collectAllAndBurn() internal override {
        quickswap.exitFarming();
        quickswap.collect(type(uint128).max, type(uint128).max);
        quickswap.burn();
    }

    function _collect() internal override {
        quickswap.collect(type(uint128).max, type(uint128).max);
    }

    function _harvest() internal virtual override {
        if (quickswap.positionTokenId == 0) {
            return;
        }
        (uint256 reward, uint256 bonusReward) = quickswap.claimFarmRewards();
        assetConverter.safeSwap(address(quickswap.farmKey.rewardToken), asset(), reward);
        assetConverter.safeSwap(address(quickswap.farmKey.bonusRewardToken), asset(), bonusReward);
        super._harvest();
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "../../libraries/AaveLibrary.sol";
import "../../libraries/ConcentratedLiquidityLibrary.sol";
import "../../libraries/PricesLibrary.sol";
import "../../libraries/SafeAssetConverter.sol";
import "./BaseHedgedConcentratedLiquidityStrategy.sol";

abstract contract BaseDynamicallyHedgedConcentratedLiquidityStrategy is BaseHedgedConcentratedLiquidityStrategy {
    using AaveLibrary for AaveLibrary.Data;
    using SafeAssetConverter for AssetConverter;
    using PricesLibrary for ChainlinkPriceFeedAggregator;

    int24 public rehedgeStep;

    constructor(int24 _rehedgeStep) {
        rehedgeStep = _rehedgeStep;
    }

    int24 public lastRehedgeTick;

    function rehedge() public {
        (int24 currentTick,) = _getPoolData();

        require(
            (currentTick > (lastRehedgeTick + int24(rehedgeStep)))
                || (currentTick < (lastRehedgeTick - int24(rehedgeStep))),
            "Tick is not far enough from last rehedge tick"
        );

        uint256 currentDebt = aave.getCurrentDebt();
        (uint160 sqrtPriceAX96, uint160 sqrtPriceX96, uint160 sqrtPriceBX96) = _getSqrtPrices();
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96, sqrtPriceAX96, sqrtPriceBX96, _getPositionData().liquidity
        );
        uint256 borrowTokenAmount = (aave.tokenToBorrow == token0()) ? amount0 : amount1;

        if (borrowTokenAmount > currentDebt) {
            uint256 amountToBorrow = borrowTokenAmount - currentDebt;
            aave.borrow(amountToBorrow);
            uint256 amountToSupply = assetConverter.safeSwap(aave.tokenToBorrow, aave.collateral, amountToBorrow);
            aave.supply(amountToSupply);
        } else if (borrowTokenAmount < currentDebt) {
            uint256 amountToRepay = currentDebt - borrowTokenAmount;
            uint256 amountToWithdraw = pricesOracle.convert(aave.tokenToBorrow, aave.collateral, amountToRepay);
            aave.withdraw(amountToWithdraw);
            amountToRepay = assetConverter.safeSwap(aave.collateral, aave.tokenToBorrow, amountToWithdraw);
            aave.repay(amountToRepay);
        }

        lastRehedgeTick = currentTick;
    }

    function _mintNewPosition(uint256 amount0, uint256 amount1) internal virtual override {
        super._mintNewPosition(amount0, amount1);
        (lastRehedgeTick,) = _getPoolData();
    }
}

pragma solidity 0.8.19;

import "../AssetConverter.sol";

library SafeAssetConverter {
    function safeSwap(AssetConverter assetConverter, address from, address to, uint256 amount)
        internal
        returns (uint256)
    {
        require(amount <= IERC20(from).balanceOf(address(this)), "SafeAssetConverter: Not enough funds for swap");
        if (from == to) return amount;
        if (amount == 0) return 0;
        return assetConverter.swap(from, to, amount);
    }

    function previewSafeSwap(AssetConverter assetConverter, address from, address to, uint256 amount)
        internal
        returns (uint256)
    {
        if (from == to) return amount;
        if (amount == 0) return 0;
        return assetConverter.previewSwap(from, to, amount);
    }
}

pragma solidity 0.8.19;

import {IAlgebraPool} from "@cryptoalgebra/core/contracts/interfaces/IAlgebraPool.sol";
import {INonfungiblePositionManager} from
    "@cryptoalgebra/periphery/contracts/interfaces/INonFungiblePositionManager.sol";
import {IFarmingCenter} from "contracts/interfaces/quickswap/IFarmingCenter.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ConcentratedLiquidityLibrary.sol";

library QuickswapV3Library {
    using SafeERC20 for IERC20;

    struct Data {
        IFarmingCenter farm;
        IFarmingCenter.IncentiveKey farmKey;
        address token0;
        address token1;
        int24 tickSpacing;
        INonfungiblePositionManager positionManager;
        IAlgebraPool pool;
        uint256 positionTokenId;
        uint256 farmTokenId;
    }

    function performApprovals(Data storage self) public {
        IERC20(self.token0).safeIncreaseAllowance(address(self.positionManager), type(uint256).max);
        IERC20(self.token1).safeIncreaseAllowance(address(self.positionManager), type(uint256).max);
    }

    function getPoolData(Data storage self) public view returns (int24 currentTick, uint160 sqrtPriceX96) {
        (sqrtPriceX96, currentTick,,,,,) = self.pool.globalState();
    }

    function getPositionData(Data storage self)
        public
        view
        returns (ConcentratedLiquidityLibrary.PositionData memory)
    {
        (,,,, int24 tickLower, int24 tickUpper, uint128 liquidity,,,,) =
            self.positionManager.positions(self.positionTokenId);
        return ConcentratedLiquidityLibrary.PositionData({
            tickLower: tickLower,
            tickUpper: tickUpper,
            liquidity: liquidity
        });
    }

    function mint(Data storage self, int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1)
        public
        returns (uint128 liquidity)
    {
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: self.token0,
            token1: self.token1,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        });
        (self.positionTokenId, liquidity,,) = self.positionManager.mint(params);
    }

    function increaseLiquidity(Data storage self, uint256 amount0, uint256 amount1) public {
        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager
            .IncreaseLiquidityParams({
            tokenId: self.positionTokenId,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });
        self.positionManager.increaseLiquidity(params);
    }

    function decreaseLiquidity(Data storage self, uint128 liquidity)
        public
        returns (uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager
            .DecreaseLiquidityParams({
            tokenId: self.positionTokenId,
            liquidity: liquidity,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp
        });
        (amount0, amount1) = self.positionManager.decreaseLiquidity(params);
    }

    function collect(Data storage self, uint256 amount0Max, uint256 amount1Max)
        public
        returns (uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: self.positionTokenId,
            recipient: address(this),
            amount0Max: uint128(amount0Max),
            amount1Max: uint128(amount1Max)
        });
        if (self.farmTokenId != 0) {
            (amount0, amount1) = self.farm.collect(params);
        } else {
            (amount0, amount1) = self.positionManager.collect(params);
        }
    }

    function burn(Data storage self) public {
        self.positionManager.burn(self.positionTokenId);
        self.positionTokenId = 0;
    }

    function enterFarming(Data storage self) public {
        if (self.positionTokenId == 0) {
            return;
        }
        if (getPositionData(self).liquidity == 0) {
            return;
        }
        self.positionManager.safeTransferFrom(address(this), address(self.farm), self.positionTokenId);
        (self.farmTokenId,,,) = self.farm.deposits(self.positionTokenId);
        self.farm.enterFarming(self.farmKey, self.positionTokenId, 0, false);
    }

    function exitFarming(Data storage self) public {
        if (self.farmTokenId == 0) {
            return;
        }
        self.farm.exitFarming(self.farmKey, self.positionTokenId, false);
        self.farm.withdrawToken(self.positionTokenId, address(this), "");
        self.farmTokenId = 0;
    }

    function claimFarmRewards(Data storage self) public returns (uint256 reward, uint256 bonusReward) {
        (reward, bonusReward) = self.farm.collectRewards(self.farmKey, self.positionTokenId);
        self.farm.claimReward(
            address(self.farmKey.rewardToken), address(this), 0, 340282366920938463463374607431768211455
        );
        self.farm.claimReward(
            address(self.farmKey.bonusRewardToken), address(this), 0, 340282366920938463463374607431768211455
        );
    }
}

pragma solidity 0.8.19;

import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "../../HarvestableApyFlowVault.sol";
import "../../libraries/Utils.sol";
import "../../libraries/SafeAssetConverter.sol";
import "../../libraries/PricesLibrary.sol";
import "../../ChainlinkPriceFeedAggregator.sol";
import "../../libraries/ConcentratedLiquidityLibrary.sol";

abstract contract BaseConcentratedLiquidityStrategy is HarvestableApyFlowVault {
    using SafeERC20 for IERC20;
    using SafeAssetConverter for AssetConverter;
    using PricesLibrary for ChainlinkPriceFeedAggregator;

    uint256 public lastPricePerToken;

    event LiquidityReadded(uint256 lastPricePerToken, uint256 pricePerTokensBefore, uint256 pricePerTokenAfter);

    ChainlinkPriceFeedAggregator public immutable pricesOracle;
    AssetConverter public immutable assetConverter;
    int24 public immutable ticksDown;
    int24 public immutable ticksUp;
    int24 public immutable ticksUntilRebalance;

    constructor(
        int24 _ticksDown,
        int24 _ticksUp,
        int24 _ticksUntilRebalance,
        ChainlinkPriceFeedAggregator _pricesOracle,
        AssetConverter _assetConverter
    ) {
        pricesOracle = _pricesOracle;
        assetConverter = _assetConverter;
        ticksDown = _ticksDown;
        ticksUp = _ticksUp;
        ticksUntilRebalance = _ticksUntilRebalance;
        lastPricePerToken = 10 ** decimals();
    }

    function token0() public view virtual returns (address);

    function token1() public view virtual returns (address);

    function _isPositionExists() internal view virtual returns (bool);

    function _increaseLiquidity(uint256 amount0, uint256 amount1) internal virtual;

    function _decreaseLiquidity(uint128 liquidity) internal virtual returns (uint256 amount0, uint256 amount1);

    function _mint(int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1) internal virtual;

    function _getPoolData() internal view virtual returns (int24 currentTick, uint160 sqrtPriceX96);

    function _getPositionData() internal view virtual returns (ConcentratedLiquidityLibrary.PositionData memory data);

    function _collectAllAndBurn() internal virtual;

    function _collect() internal virtual;

    function _tickSpacing() internal view virtual returns (int24);

    function _performApprovals() internal virtual {
        Utils.approveIfZeroAllowance(asset(), address(assetConverter));
        Utils.approveIfZeroAllowance(token0(), address(assetConverter));
        Utils.approveIfZeroAllowance(token1(), address(assetConverter));
    }

    function _isInRange() internal view returns (bool) {
        (int24 tickLower, int24 currentTick, int24 tickUpper) = _getTicks();
        return (tickLower <= currentTick) && (currentTick <= tickUpper);
    }

    function _getTicks() internal view returns (int24 tickLower, int24 currentTick, int24 tickUpper) {
        (currentTick,) = _getPoolData();
        if (_isPositionExists()) {
            ConcentratedLiquidityLibrary.PositionData memory data = _getPositionData();
            tickLower = data.tickLower;
            tickUpper = data.tickUpper;
        } else {
            tickLower = currentTick - ticksDown;
            tickUpper = currentTick + ticksUp;
            int24 spacing = _tickSpacing();
            tickLower = (tickLower / spacing) * spacing;
            tickUpper = (tickUpper / spacing) * spacing;
        }
    }

    function _getSqrtPrices()
        internal
        view
        returns (uint160 sqrtPriceAX96, uint160 sqrtPriceX96, uint160 sqrtPriceBX96)
    {
        (int24 tickLower, int24 currentTick, int24 tickUpper) = _getTicks();
        sqrtPriceAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        sqrtPriceX96 = TickMath.getSqrtRatioAtTick(currentTick);
        sqrtPriceBX96 = TickMath.getSqrtRatioAtTick(tickUpper);
    }

    function _mintNewPosition(uint256 amount0, uint256 amount1) internal virtual {
        (int24 tickLower, int24 currentTick, int24 tickUpper) = _getTicks();
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(currentTick),
            TickMath.getSqrtRatioAtTick(tickUpper),
            amount0,
            amount1
        );
        if (liquidity == 0) {
            return;
        }
        _mint(tickLower, tickUpper, amount0, amount1);
    }

    function _increaseLiquidityOrMintPosition(uint256 amount0, uint256 amount1) internal {
        (uint160 sqrtPriceAX96, uint160 sqrtPriceX96, uint160 sqrtPriceBX96) = _getSqrtPrices();
        uint128 liquidity =
            LiquidityAmounts.getLiquidityForAmounts(sqrtPriceAX96, sqrtPriceX96, sqrtPriceBX96, amount0, amount1);
        if (liquidity == 0) {
            return;
        }
        if (!_isPositionExists()) {
            _mintNewPosition(amount0, amount1);
        } else {
            _increaseLiquidity(amount0, amount1);
        }
    }

    function _totalAssets() internal view virtual override returns (uint256 assets) {
        if (!_isPositionExists()) {
            return 0;
        }
        (uint160 sqrtPriceAX96, uint160 sqrtPriceX96, uint160 sqrtPriceBX96) = _getSqrtPrices();
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96, sqrtPriceAX96, sqrtPriceBX96, _getPositionData().liquidity
        );
        uint256 valueInUSD;
        valueInUSD += pricesOracle.convertToUSD(token0(), amount0);
        valueInUSD += pricesOracle.convertToUSD(token1(), amount1);
        assets = pricesOracle.convertFromUSD(valueInUSD, asset());
    }

    function _deposit(uint256 assets) internal virtual override {
        (uint160 sqrtPriceAX96, uint160 sqrtPriceX96, uint160 sqrtPriceBX96) = _getSqrtPrices();
        (uint256 amountFor0, uint256 amountFor1) = ConcentratedLiquidityLibrary.getAmountsForLiquidityProviding(
            sqrtPriceAX96, sqrtPriceX96, sqrtPriceBX96, assets
        );
        uint256 amount0 = assetConverter.safeSwap(asset(), token0(), amountFor0);
        uint256 amount1 = assetConverter.safeSwap(asset(), token1(), amountFor1);
        _increaseLiquidityOrMintPosition(amount0, amount1);
        assetConverter.safeSwap(token0(), asset(), IERC20(token0()).balanceOf(address(this)));
        assetConverter.safeSwap(token1(), asset(), IERC20(token1()).balanceOf(address(this)));
    }

    function _redeem(uint256 shares) internal virtual override returns (uint256 assets) {
        uint128 liquidity = uint128((_getPositionData().liquidity * shares) / totalSupply());

        (uint256 amount0, uint256 amount1) = _decreaseLiquidity(liquidity);

        _collect();

        if (_getPositionData().liquidity == 0) {
            _collectAllAndBurn();
        }

        assets += assetConverter.safeSwap(token0(), asset(), amount0);
        assets += assetConverter.safeSwap(token1(), asset(), amount1);
    }

    function _readdLiquidity() internal virtual {
        _deposit(_redeem(totalSupply()));
    }

    function _harvest() internal virtual override {
        if (!_isPositionExists()) return;
        _collect();
        assetConverter.safeSwap(token0(), asset(), IERC20(token0()).balanceOf(address(this)));
        assetConverter.safeSwap(token1(), asset(), IERC20(token1()).balanceOf(address(this)));
    }

    function readdLiquidity() public virtual {
        _harvest(false);
        ConcentratedLiquidityLibrary.PositionData memory data = _getPositionData();

        (int24 currentTick,) = _getPoolData();
        int24 tickLowerToRebalance = data.tickLower + ticksUntilRebalance;
        int24 tickUpperToRebalance = data.tickUpper - ticksUntilRebalance;
        bool isInRebalanceRange = (tickLowerToRebalance > currentTick) || (tickUpperToRebalance < currentTick);

        uint256 pricePerTokenBefore = pricePerToken();
        _readdLiquidity();
        uint256 pricePerTokenAfter = pricePerToken();

        require(isInRebalanceRange || (pricePerTokenAfter >= (lastPricePerToken * 1001) / 1000));

        emit LiquidityReadded(lastPricePerToken, pricePerTokenBefore, pricePerTokenAfter);

        lastPricePerToken = pricePerTokenAfter;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        unchecked {
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
            uint256 twos = (0 - denominator) & denominator;
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
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
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
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAavePool} from "contracts/interfaces/aave/IAavePool.sol";
import {IAavePriceOracle} from "contracts/interfaces/aave/IAavePriceOracle.sol";

library AaveLibrary {
    using SafeERC20 for IERC20;

    struct Data {
        IAavePool aavePool;
        IAavePriceOracle aavePriceOracle;
        address tokenToBorrow;
        address collateral;
        uint256 ltv; // in 10^-6s
    }

    function performApprovals(Data storage self) public {
        IERC20(self.tokenToBorrow).safeIncreaseAllowance(address(self.aavePool), type(uint256).max);
        IERC20(self.collateral).safeIncreaseAllowance(address(self.aavePool), type(uint256).max);
        IERC20(self.aavePool.getReserveData(self.collateral).aTokenAddress).safeIncreaseAllowance(
            address(self.aavePool), type(uint256).max
        );
    }

    function getCurrentLtv(Data storage self) public view returns (uint256) {
        uint256 collateral = getCurrentCollateralSupply(self);
        uint256 collateralValue = (collateral * self.aavePriceOracle.getAssetPrice(address(self.collateral)))
            / (10 ** IERC20Metadata(self.collateral).decimals());

        if (collateralValue == 0) {
            return self.ltv;
        }

        uint256 debt = getCurrentDebt(self);
        uint256 debtValue = (debt * self.aavePriceOracle.getAssetPrice(address(self.tokenToBorrow)))
            / (10 ** IERC20Metadata(self.tokenToBorrow).decimals());
        if (debtValue == 0) {
            return self.ltv;
        }
        return (debtValue * 1000000) / collateralValue;
    }

    function getCurrentCollateralSupply(Data storage self) public view returns (uint256) {
        return IERC20(self.aavePool.getReserveData(address(self.collateral)).aTokenAddress).balanceOf(address(this));
    }

    function getCurrentDebt(Data storage self) public view returns (uint256) {
        return IERC20(self.aavePool.getReserveData(address(self.tokenToBorrow)).variableDebtTokenAddress).balanceOf(
            address(this)
        );
    }

    function getNeededDebt(Data storage self, uint256 collateral, uint256 ltv)
        public
        view
        returns (uint256 neededDebt)
    {
        uint256 collateralValue = (collateral * self.aavePriceOracle.getAssetPrice(address(self.collateral)))
            / (10 ** IERC20Metadata(self.collateral).decimals());
        uint256 neededDebtValue = (collateralValue * ltv) / 1000000;
        neededDebt = (neededDebtValue * 10 ** IERC20Metadata(self.tokenToBorrow).decimals())
            / self.aavePriceOracle.getAssetPrice(address(self.tokenToBorrow));
    }

    function supply(Data storage self, uint256 amount) public {
        if (amount > 0) {
            self.aavePool.supply(address(self.collateral), amount, address(this), 0);
        }
    }

    function withdraw(Data storage self, uint256 amount) public {
        if (amount > 0) {
            self.aavePool.withdraw(address(self.collateral), amount, address(this));
        }
    }

    function borrow(Data storage self, uint256 amount) public {
        if (amount > 0) {
            self.aavePool.borrow(address(self.tokenToBorrow), amount, 2, 0, address(this));
        }
    }

    function repay(Data storage self, uint256 amount) public {
        if (amount > 0) {
            self.aavePool.repay(address(self.tokenToBorrow), amount, 2, address(this));
        }
    }

    function repayAndWithdraw(Data storage self, uint256 debt) public returns (uint256 collateral) {
        uint256 totalDebt = getCurrentDebt(self);
        uint256 totalCollateral = getCurrentCollateralSupply(self);
        collateral = (debt * totalCollateral) / totalDebt;
        repay(self, debt);
        withdraw(self, collateral);
    }

    function flashloan(Data storage self, address asset, uint256 amount) public {
        self.aavePool.flashLoanSimple(address(this), asset, amount, "", 0);
    }
}

pragma solidity 0.8.19;

import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

library ConcentratedLiquidityLibrary {
    struct PositionData {
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    function getAmountsForLiquidityProviding(
        uint160 sqrtPriceAX96,
        uint160 sqrtPriceX96,
        uint160 sqrtPriceBX96,
        uint256 assets
    ) internal pure returns (uint256 amountFor0, uint256 amountFor1) {
        if (sqrtPriceX96 <= sqrtPriceAX96) {
            amountFor0 = assets;
        } else if (sqrtPriceX96 < sqrtPriceBX96) {
            uint256 n = FullMath.mulDiv(sqrtPriceBX96, sqrtPriceX96 - sqrtPriceAX96, FixedPoint96.Q96);
            uint256 d = FullMath.mulDiv(sqrtPriceX96, sqrtPriceBX96 - sqrtPriceX96, FixedPoint96.Q96);
            uint256 x = FullMath.mulDiv(n, FixedPoint96.Q96, d);
            amountFor0 = FullMath.mulDiv(assets, FixedPoint96.Q96, x + FixedPoint96.Q96);
            amountFor1 = assets - amountFor0;
        } else {
            amountFor1 = assets;
        }
    }
}

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../ChainlinkPriceFeedAggregator.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

library PricesLibrary {
    function getUSDPrice(ChainlinkPriceFeedAggregator oracle, address asset) internal view returns (uint256) {
        return oracle.getRate(asset);
    }

    function convertToUSD(ChainlinkPriceFeedAggregator oracle, address asset, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return (amount * oracle.getRate(asset)) / 10 ** IERC20Metadata(asset).decimals();
    }

    function convertFromUSD(ChainlinkPriceFeedAggregator oracle, uint256 usdAmount, address toAsset)
        internal
        view
        returns (uint256)
    {
        return usdAmount * 10 ** IERC20Metadata(toAsset).decimals() / oracle.getRate(toAsset);
    }

    function convert(ChainlinkPriceFeedAggregator oracle, address from, address to, uint256 amount)
        internal
        view
        returns (uint256)
    {
        return convertFromUSD(oracle, convertToUSD(oracle, from, amount), to);
    }
}

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "../../libraries/AaveLibrary.sol";
import "../../libraries/ConcentratedLiquidityLibrary.sol";
import "../../libraries/PricesLibrary.sol";
import "../../libraries/SafeAssetConverter.sol";
import "./BaseConcentratedLiquidityStrategy.sol";

abstract contract BaseHedgedConcentratedLiquidityStrategy is BaseConcentratedLiquidityStrategy {
    using SafeERC20 for IERC20;
    using AaveLibrary for AaveLibrary.Data;
    using SafeAssetConverter for AssetConverter;
    using PricesLibrary for ChainlinkPriceFeedAggregator;

    AaveLibrary.Data public aave;

    constructor(AaveLibrary.Data memory _aave) {
        aave = _aave;
        aave.performApprovals();
    }

    function _totalAssets() internal view virtual override returns (uint256 assets) {
        assets = super._totalAssets();
        uint256 valueInUSD = pricesOracle.convertToUSD(asset(), assets);
        valueInUSD += pricesOracle.convertToUSD(aave.collateral, aave.getCurrentCollateralSupply());
        valueInUSD -= pricesOracle.convertToUSD(aave.tokenToBorrow, aave.getCurrentDebt());
        assets = pricesOracle.convertFromUSD(valueInUSD, asset());
    }

    function getAmounts(uint256 assets)
        public
        view
        returns (
            uint256 amountToSupply,
            uint256 amountToBorrow,
            uint256 amountFor0,
            uint256 amountFor1,
            uint256 extraDebt
        )
    {
        (uint160 sqrtPriceAX96, uint160 sqrtPriceX96, uint160 sqrtPriceBX96) = _getSqrtPrices();
        uint256 ltv;
        if (!_isPositionExists()) {
            ltv = aave.ltv;
            (amountFor0, amountFor1) = ConcentratedLiquidityLibrary.getAmountsForLiquidityProviding(
                sqrtPriceAX96, sqrtPriceX96, sqrtPriceBX96, assets
            );
            (uint256 amountForDebt, uint256 amountForCollateral) =
                (token0() == aave.tokenToBorrow) ? (amountFor0, amountFor1) : (amountFor1, amountFor0);

            uint256 delta = Math.mulDiv(
                amountForDebt - (ltv * amountForDebt) / 1000000,
                amountForCollateral,
                amountForDebt + (ltv * amountForCollateral) / 1000000
            );
            amountToSupply = amountForDebt + delta;
            amountForDebt = 0;
            amountForCollateral -= delta;
            (amountFor0, amountFor1) = (token0() == aave.tokenToBorrow)
                ? (amountForDebt, amountForCollateral)
                : (amountForCollateral, amountForDebt);
        } else {
            ltv = aave.getCurrentLtv();
            amountToSupply = (aave.getCurrentCollateralSupply() * assets) / _totalAssets();
            // exclude assets locked as collateral: (1 - ltv) * collateral
            assets -= Math.mulDiv(amountToSupply, 1000000 - ltv, 1000000, Math.Rounding.Up);
            uint256 assetsInDebt = amountToSupply * ltv / 1000000;
            (amountFor0, amountFor1) = ConcentratedLiquidityLibrary.getAmountsForLiquidityProviding(
                sqrtPriceAX96, sqrtPriceX96, sqrtPriceBX96, assets
            );
            (uint256 amountForDebt, uint256 amountForCollateral) =
                (token0() == aave.tokenToBorrow) ? (amountFor0, amountFor1) : (amountFor1, amountFor0);
            if (amountForDebt >= assetsInDebt) {
                amountForDebt -= assetsInDebt;
            } else {
                uint256 extraDebtAssets = assetsInDebt - amountForDebt;
                amountForCollateral -= extraDebtAssets;
                extraDebt = pricesOracle.convert(asset(), aave.tokenToBorrow, extraDebtAssets);
                amountForDebt = 0;
            }
            (amountFor0, amountFor1) = (token0() == aave.tokenToBorrow)
                ? (amountForDebt, amountForCollateral)
                : (amountForCollateral, amountForDebt);
        }
        amountToBorrow = aave.getNeededDebt(amountToSupply, ltv);
    }

    function _deposit(uint256 assets) internal virtual override {
        (uint256 amountToSupply, uint256 amountToBorrow, uint256 amountFor0, uint256 amountFor1, uint256 extraDebt) =
            getAmounts(assets);
        aave.supply(amountToSupply);
        aave.borrow(amountToBorrow);
        uint256 tokenToBorrowAmount = amountToBorrow;
        tokenToBorrowAmount -= extraDebt;
        uint256 collateralAmount = assetConverter.safeSwap(aave.tokenToBorrow, aave.collateral, extraDebt);

        (uint256 amount0, uint256 amount1) = (token0() == aave.collateral)
            ? (collateralAmount, tokenToBorrowAmount)
            : (tokenToBorrowAmount, collateralAmount);

        amount0 += assetConverter.safeSwap(asset(), token0(), amountFor0);
        amount1 += assetConverter.safeSwap(asset(), token1(), amountFor1);

        _increaseLiquidityOrMintPosition(amount0, amount1);

        assetConverter.safeSwap(token0(), asset(), IERC20(token0()).balanceOf(address(this)));
        assetConverter.safeSwap(token1(), asset(), IERC20(token1()).balanceOf(address(this)));
    }

    function _redeem(uint256 shares) internal virtual override returns (uint256 assets) {
        uint128 liquidity = uint128((_getPositionData().liquidity * shares) / totalSupply());

        (uint256 amount0, uint256 amount1) = (liquidity > 0) ? _decreaseLiquidity(liquidity) : (0, 0);
        _collect();

        if (_getPositionData().liquidity == 0) {
            _collectAllAndBurn();
        }

        uint256 debtToRepay = (aave.getCurrentDebt() * shares) / totalSupply();

        (uint256 tokenToBorrowAmount, uint256 collateralAmount) =
            (token0() == aave.collateral) ? (amount1, amount0) : (amount0, amount1);

        if (tokenToBorrowAmount < debtToRepay) {
            uint256 amountToSwap =
                pricesOracle.convert(aave.tokenToBorrow, aave.collateral, debtToRepay - tokenToBorrowAmount);
            amountToSwap = Math.min(amountToSwap, collateralAmount);
            tokenToBorrowAmount += assetConverter.safeSwap(aave.collateral, aave.tokenToBorrow, amountToSwap);
            collateralAmount -= amountToSwap;
            debtToRepay = Math.min(debtToRepay, tokenToBorrowAmount);
        }
        tokenToBorrowAmount -= debtToRepay;
        collateralAmount += aave.repayAndWithdraw(debtToRepay);

        (amount0, amount1) = (token0() == aave.collateral)
            ? (collateralAmount, tokenToBorrowAmount)
            : (tokenToBorrowAmount, collateralAmount);

        assets += assetConverter.safeSwap(token0(), asset(), amount0);
        assets += assetConverter.safeSwap(token1(), asset(), amount1);
    }

    function _readdLiquidity() internal virtual override {
        _decreaseLiquidity(_getPositionData().liquidity);
        _collectAllAndBurn();

        uint256 assets = _totalAssets();
        assets += pricesOracle.convert(token0(), asset(), IERC20(token0()).balanceOf(address(this)));
        assets += pricesOracle.convert(token1(), asset(), IERC20(token1()).balanceOf(address(this)));
        (uint256 neededCollateral, uint256 neededDebt,,,) = getAmounts(assets);

        uint256 currentCollateral = aave.getCurrentCollateralSupply();
        uint256 currentDebt = aave.getCurrentDebt();
        uint256 tokenToBorrowBalance = IERC20(aave.tokenToBorrow).balanceOf(address(this));
        uint256 collateralBalance = IERC20(aave.collateral).balanceOf(address(this));

        uint256 amountToRepay = (currentDebt > neededDebt) ? currentDebt - neededDebt : 0;
        uint256 amountToWithdraw = (currentCollateral > neededCollateral) ? currentCollateral - neededCollateral : 0;
        uint256 amountToBorrow = (neededDebt > currentDebt) ? neededDebt - currentDebt : 0;
        uint256 amountToSupply = (neededCollateral > currentCollateral) ? neededCollateral - currentCollateral : 0;

        uint256 amountToSwap;
        if (amountToRepay > 0) {
            if (tokenToBorrowBalance < amountToRepay) {
                amountToSwap =
                    pricesOracle.convert(aave.tokenToBorrow, aave.collateral, amountToRepay - tokenToBorrowBalance);
                collateralBalance -= amountToSwap;
                tokenToBorrowBalance += assetConverter.safeSwap(aave.collateral, aave.tokenToBorrow, amountToSwap);
                amountToRepay = Math.min(tokenToBorrowBalance, amountToRepay);
            }
            aave.repay(amountToRepay);
            tokenToBorrowBalance -= amountToRepay;
            currentDebt -= amountToRepay;
        }
        if (amountToWithdraw > 0) {
            aave.withdraw(amountToWithdraw);
            collateralBalance += amountToWithdraw;
            currentCollateral -= amountToWithdraw;
        } else {
            // amountToSupply > 0
            if (collateralBalance < amountToSupply) {
                amountToSwap =
                    pricesOracle.convert(aave.collateral, aave.tokenToBorrow, amountToSupply - collateralBalance);
                tokenToBorrowBalance -= amountToSwap;
                collateralBalance += assetConverter.safeSwap(aave.tokenToBorrow, aave.collateral, amountToSwap);
                amountToSupply = Math.min(collateralBalance, amountToSupply);
            }
            aave.supply(amountToSupply);
            collateralBalance -= amountToSupply;
            currentCollateral += amountToSupply;
        }
        if (amountToBorrow > 0) {
            aave.borrow(amountToBorrow);
            tokenToBorrowBalance += amountToBorrow;
            currentDebt += amountToBorrow;
        }

        if (tokenToBorrowBalance > neededDebt) {
            assetConverter.safeSwap(aave.tokenToBorrow, aave.collateral, tokenToBorrowBalance - neededDebt);
        } else if (tokenToBorrowBalance < neededDebt) {
            amountToSwap = Math.min(
                pricesOracle.convert(aave.tokenToBorrow, aave.collateral, neededDebt - tokenToBorrowBalance),
                collateralBalance
            );
            assetConverter.safeSwap(aave.collateral, aave.tokenToBorrow, amountToSwap);
        }
        uint256 amount0 = IERC20(token0()).balanceOf(address(this));
        uint256 amount1 = IERC20(token1()).balanceOf(address(this));
        _mintNewPosition(amount0, amount1);
    }
}

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ChainlinkPriceFeedAggregator.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IConverter.sol";

contract AssetConverter is Ownable {
    using SafeERC20 for IERC20;

    error SlippageTooBig(address source, address destination, uint256 amountIn, uint256 amountOut);

    ChainlinkPriceFeedAggregator public immutable pricesOracle;
    uint256 private defaultMaxAllowedSlippage = 20; // in 10^-3s

    constructor(ChainlinkPriceFeedAggregator _pricesOracle) {
        pricesOracle = _pricesOracle;
    }

    struct RouteData {
        IConverter converter;
        uint256 maxAllowedSlippage;
    }

    mapping(address => mapping(address => RouteData)) public routes;
    mapping(address => mapping(address => address[])) public complexRoutes;

    struct RouteDataUpdate {
        address source;
        address destination;
        RouteData data;
    }

    function updateRoutes(RouteDataUpdate[] calldata updates) public onlyOwner {
        for (uint256 i = 0; i < updates.length; i++) {
            routes[updates[i].source][updates[i].destination] = updates[i].data;
        }
    }

    struct ComplexRouteUpdate {
        address source;
        address destination;
        address[] complexRoutes;
    }

    function updateComplexRoutes(ComplexRouteUpdate[] calldata updates) public onlyOwner {
        for (uint256 i = 0; i < updates.length; i++) {
            complexRoutes[updates[i].source][updates[i].destination] = updates[i].complexRoutes;
        }
    }

    function _checkSlippage(address source, address destination, uint256 amountIn, uint256 amountOut)
        internal
        view
        returns (bool)
    {
        // If amountIn is low enough, than fee substraction may substract 1
        // And in case in low amountIn this can make big difference
        amountIn -= 1;
        uint256 maxSlippage = routes[source][destination].maxAllowedSlippage;
        if (maxSlippage == 0) {
            maxSlippage = defaultMaxAllowedSlippage;
        }

        uint256 sourceUSDPrice;
        uint256 destinationUSDPrice;
        try pricesOracle.getRate(source) returns (uint256 price) {
            sourceUSDPrice = price;
        } catch {
            return true;
        }
        try pricesOracle.getRate(destination) returns (uint256 price) {
            destinationUSDPrice = price;
        } catch {
            return true;
        }

        uint256 sourceUSDValue = (amountIn * sourceUSDPrice) / (10 ** IERC20Metadata(source).decimals());
        uint256 expected = (sourceUSDValue * (10 ** IERC20Metadata(destination).decimals())) / destinationUSDPrice;
        return (amountOut >= (expected * (1000 - maxSlippage)) / 1000);
    }

    function _getRoute(address source, address destination)
        internal
        view
        returns (address[] memory tokens, IConverter[] memory converters)
    {
        uint256 complexRoutesLength = complexRoutes[source][destination].length;
        tokens = new address[](2 + complexRoutesLength);
        converters = new IConverter[](tokens.length - 1);
        tokens[0] = source;
        for (uint256 i = 0; i < complexRoutesLength; i++) {
            tokens[i + 1] = complexRoutes[source][destination][i];
        }
        tokens[tokens.length - 1] = destination;
        for (uint256 i = 0; i < tokens.length - 1; i++) {
            converters[i] = routes[tokens[i]][tokens[i + 1]].converter;
            require(address(converters[i]) != address(0), "AssetConverter: No converter specified for the route");
        }
    }

    function swap(address source, address destination, uint256 amountIn) external returns (uint256) {
        (address[] memory tokens, IConverter[] memory converters) = _getRoute(source, destination);

        IERC20(source).safeTransferFrom(msg.sender, address(converters[0]), amountIn);

        for (uint256 i = 0; i < tokens.length - 1; i++) {
            if (amountIn == 0) {
                return 0;
            }

            address to = i < tokens.length - 2 ? address(converters[i + 1]) : msg.sender;
            IConverter converter = converters[i];
            uint256 amountOut = converter.swap(tokens[i], tokens[i + 1], amountIn, to);
            if (!_checkSlippage(tokens[i], tokens[i + 1], amountIn, amountOut)) {
                revert SlippageTooBig(tokens[i], tokens[i + 1], amountIn, amountOut);
            }

            amountIn = amountOut;
        }
        return amountIn;
    }

    function previewSwap(address source, address destination, uint256 value) external returns (uint256) {
        (address[] memory tokens, IConverter[] memory converters) = _getRoute(source, destination);

        for (uint256 i = 0; i < tokens.length - 1; i++) {
            IConverter converter = converters[i];
            value = converter.previewSwap(tokens[i], tokens[i + 1], value);
        }
        return value;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IAlgebraPoolImmutables.sol';
import './pool/IAlgebraPoolState.sol';
import './pool/IAlgebraPoolDerivedState.sol';
import './pool/IAlgebraPoolActions.sol';
import './pool/IAlgebraPoolPermissionedActions.sol';
import './pool/IAlgebraPoolEvents.sol';

/// @title The interface for a Algebra Pool
/// @dev The pool interface is broken up into many smaller pieces.
/// Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPool is
  IAlgebraPoolImmutables,
  IAlgebraPoolState,
  IAlgebraPoolDerivedState,
  IAlgebraPoolActions,
  IAlgebraPoolPermissionedActions,
  IAlgebraPoolEvents
{
  // used only for combining interfaces
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Algebra positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param actualLiquidity the actual liquidity that was added into a pool. Could differ from
    /// _liquidity_ when using FeeOnTransfer tokens
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint128 actualLiquidity,
        uint256 amount0,
        uint256 amount1,
        address pool
    );

    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Emitted if farming failed in call from NonfungiblePositionManager.
    /// @dev Should never be emitted
    /// @param tokenId The ID of corresponding token
    event FarmingFailed(uint256 indexed tokenId);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint88 nonce,
            address operator,
            address token0,
            address token1,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to achieve resulting liquidity
    /// @return amount1 The amount of token1 to achieve resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    /// @notice Changes approval of token ID for farming.
    /// @param tokenId The ID of the token that is being approved / unapproved
    /// @param approve New status of approval
    function approveForFarming(uint256 tokenId, bool approve) external payable;

    /// @notice Changes farming status of token to 'farmed' or 'not farmed'
    /// @dev can be called only by farmingCenter
    /// @param tokenId tokenId The ID of the token
    /// @param tokenId isFarmed The new status
    function switchFarmingStatus(uint256 tokenId, bool isFarmed) external;

    /// @notice Changes address of farmingCenter
    /// @dev can be called only by factory owner or NONFUNGIBLE_POSITION_MANAGER_ADMINISTRATOR_ROLE
    /// @param newFarmingCenter The new address of farmingCenter
    function setFarmingCenter(address newFarmingCenter) external;
}

pragma solidity ^0.8.10;

import {INonfungiblePositionManager} from
    "@cryptoalgebra/periphery/contracts/interfaces/INonFungiblePositionManager.sol";

interface IFarmingCenter {
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event DepositTransferred(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    struct IncentiveKey {
        address rewardToken;
        address bonusRewardToken;
        address pool;
        uint256 startTime;
        uint256 endTime;
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function WNativeToken() external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
    function baseURI() external view returns (string memory);
    function claimReward(
        address rewardToken,
        address to,
        uint256 amountRequestedIncentive,
        uint256 amountRequestedEternal
    ) external returns (uint256 reward);
    function collect(INonfungiblePositionManager.CollectParams memory params)
        external
        returns (uint256 amount0, uint256 amount1);
    function collectRewards(IFarmingCenter.IncentiveKey memory key, uint256 tokenId)
        external
        returns (uint256 reward, uint256 bonusReward);
    function connectVirtualPool(address pool, address newVirtualPool) external;
    function cross(int24 nextTick, bool zeroToOne) external;
    function deposits(uint256)
        external
        view
        returns (uint256 L2TokenId, uint32 numberOfFarms, bool inLimitFarming, address owner);
    function enterFarming(IFarmingCenter.IncentiveKey memory key, uint256 tokenId, uint256 tokensLocked, bool isLimit)
        external;
    function eternalFarming() external view returns (address);
    function exitFarming(IFarmingCenter.IncentiveKey memory key, uint256 tokenId, bool isLimit) external;
    function farmingCenterVault() external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function increaseCumulative(uint32 blockTimestamp) external returns (uint8 status);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function l2Nfts(uint256) external view returns (uint96 nonce, address operator, uint256 tokenId);
    function limitFarming() external view returns (address);
    function multicall(bytes[] memory data) external payable returns (bytes[] memory results);
    function name() external view returns (string memory);
    function nonfungiblePositionManager() external view returns (address);
    function onERC721Received(address, address from, uint256 tokenId, bytes memory) external returns (bytes4);
    function ownerOf(uint256 tokenId) external view returns (address);
    function permit(address spender, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        payable;
    function refundNativeToken() external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable;
    function symbol() external view returns (string memory);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function unwrapWNativeToken(uint256 amountMinimum, address recipient) external payable;
    function virtualPoolAddresses(address pool) external view returns (address limitVP, address eternalVP);
    function withdrawToken(uint256 tokenId, address to, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';

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
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
        }
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
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
        }
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
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

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
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                FullMath.mulDiv(
                    uint256(liquidity) << FixedPoint96.RESOLUTION,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    sqrtRatioBX96
                ) / sqrtRatioAX96;
        }
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
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        unchecked {
            return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
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
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

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

pragma solidity 0.8.19;

import "./ApyFlowVault.sol";
import "./interfaces/IHarvestableApyFlowVault.sol";

abstract contract HarvestableApyFlowVault is ApyFlowVault {
    event Harvested(uint256 assets);

    function _harvest() internal virtual;

    function _harvest(bool reinvest) internal returns (uint256 harvested) {
        uint256 balanceBefore = IERC20(asset()).balanceOf(address(this));
        _harvest();
        uint256 balanceAfter = IERC20(asset()).balanceOf(address(this));
        if (reinvest) {
            if (balanceAfter > 0) {
                _deposit(balanceAfter);
            }
        }
        harvested = balanceAfter - balanceBefore;
        emit Harvested(harvested);
    }

    function harvest() public returns (uint256 harvested) {
        return _harvest(true);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IHarvestableApyFlowVault).interfaceId || super.supportsInterface(interfaceId);
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        _harvest(true);
        return super.deposit(assets, receiver);
    }

    function _performRedeem(uint256 shares) internal override returns (uint256 assets) {
        // some protocols do not allow us to perform deposit and redeem in one transaction
        // for example, Aave do not allow to borrow and repay in a same block
        // also, this prevents errors which may occur due to paused deposits into the protocol
        _harvest(false);
        return super._performRedeem(shares);
    }
}

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Utils {
    using SafeERC20 for IERC20;

    function approveIfZeroAllowance(address asset, address spender) internal {
        if (IERC20(asset).allowance(address(this), spender) == 0) {
            IERC20(asset).safeIncreaseAllowance(spender, type(uint256).max);
        }
    }

    function revokeAllowance(address asset, address spender) internal {
        uint256 allowance = IERC20(asset).allowance(address(this), spender);
        if (allowance > 0) {
            IERC20(asset).safeDecreaseAllowance(spender, allowance);
        }
    }
}

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IChainlinkOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

contract ChainlinkPriceFeedAggregator is Ownable {
    mapping(address => IChainlinkOracle) public oracles;

    function updateOracles(address[] calldata tokens, IChainlinkOracle[] calldata newOracles) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            oracles[tokens[i]] = newOracles[i];
        }
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function getRate(address token) external view returns (uint256) {
        IChainlinkOracle oracle = oracles[token];
        return uint256(oracle.latestAnswer()) * (10 ** decimals()) / (10 ** oracle.decimals());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

pragma solidity ^0.8.10;

interface IAavePool {
    event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint8 interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        uint8 interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );
    event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );
    event MintUnbacked(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode
    );
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);
    event Repay(
        address indexed reserve, address indexed user, address indexed repayer, uint256 amount, bool useATokens
    );
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);
    event Supply(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode
    );
    event SwapBorrowRateMode(address indexed reserve, address indexed user, uint8 interestRateMode);
    event UserEModeSet(address indexed user, uint8 categoryId);
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    struct EModeCategory {
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        address priceSource;
        string label;
    }

    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct ReserveData {
        ReserveConfigurationMap configuration;
        uint128 liquidityIndex;
        uint128 currentLiquidityRate;
        uint128 variableBorrowIndex;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        uint16 id;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint128 accruedToTreasury;
        uint128 unbacked;
        uint128 isolationModeTotalDebt;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    function ADDRESSES_PROVIDER() external view returns (address);
    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);
    function MAX_NUMBER_RESERVES() external view returns (uint16);
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);
    function POOL_REVISION() external view returns (uint256);
    function backUnbacked(address asset, uint256 amount, uint256 fee) external returns (uint256);
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external;
    function configureEModeCategory(uint8 id, EModeCategory memory category) external;
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function dropReserve(address asset) external;
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;
    function flashLoan(
        address receiverAddress,
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory interestRateModes,
        address onBehalfOf,
        bytes memory params,
        uint16 referralCode
    ) external;
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes memory params,
        uint16 referralCode
    ) external;
    function getConfiguration(address asset) external view returns (ReserveConfigurationMap memory);
    function getEModeCategoryData(uint8 id) external view returns (EModeCategory memory);
    function getReserveAddressById(uint16 id) external view returns (address);
    function getReserveData(address asset) external view returns (ReserveData memory);
    function getReserveNormalizedIncome(address asset) external view returns (uint256);
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);
    function getReservesList() external view returns (address[] memory);
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );
    function getUserConfiguration(address user) external view returns (UserConfigurationMap memory);
    function getUserEMode(address user) external view returns (uint256);
    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;
    function initialize(address provider) external;
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;
    function mintToTreasury(address[] memory assets) external;
    function mintUnbacked(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function rebalanceStableBorrowRate(address asset, address user) external;
    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
        external
        returns (uint256);
    function repayWithATokens(address asset, uint256 amount, uint256 interestRateMode) external returns (uint256);
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);
    function rescueTokens(address token, address to, uint256 amount) external;
    function resetIsolationModeTotalDebt(address asset) external;
    function setConfiguration(address asset, ReserveConfigurationMap memory configuration) external;
    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress) external;
    function setUserEMode(uint8 categoryId) external;
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;
    function swapBorrowRateMode(address asset, uint256 interestRateMode) external;
    function updateBridgeProtocolFee(uint256 protocolFee) external;
    function updateFlashloanPremiums(uint128 flashLoanPremiumTotal, uint128 flashLoanPremiumToProtocol) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

pragma solidity ^0.8.10;

interface IAavePriceOracle {
    event AssetSourceUpdated(address indexed asset, address indexed source);
    event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);
    event FallbackOracleUpdated(address indexed fallbackOracle);

    function ADDRESSES_PROVIDER() external view returns (address);
    function BASE_CURRENCY() external view returns (address);
    function BASE_CURRENCY_UNIT() external view returns (uint256);
    function getAssetPrice(address asset) external view returns (uint256);
    function getAssetsPrices(address[] memory assets) external view returns (uint256[] memory);
    function getFallbackOracle() external view returns (address);
    function getSourceOfAsset(address asset) external view returns (address);
    function setAssetSources(address[] memory assets, address[] memory sources) external;
    function setFallbackOracle(address fallbackOracle) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

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
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
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
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
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

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity 0.8.19;

interface IConverter {
    function swap(address source, address destination, uint256 value, address beneficiary) external returns (uint256);

    function previewSwap(address source, address destination, uint256 value) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolImmutables {
  /// @notice The contract that stores all the timepoints and can perform actions with them
  /// @return The operator address
  function dataStorageOperator() external view returns (address);

  /// @notice The contract that deployed the pool, which must adhere to the IAlgebraFactory interface
  /// @return The contract address
  function factory() external view returns (address);

  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (address);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (address);

  /// @notice The contract to which community fees are transferred
  /// @return The communityVault address
  function communityVault() external view returns (address);

  /// @notice The maximum amount of position liquidity that can use any tick in the range
  /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
  /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
  /// @return The max amount of liquidity per tick
  function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolState {
  /// @notice The globalState structure in the pool stores many values but requires only one slot
  /// and is exposed as a single method to save gas when accessed externally.
  /// @return price The current price of the pool as a sqrt(dToken1/dToken0) Q64.96 value;
  /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run;
  /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick boundary;
  /// @return prevInitializedTick The previous initialized tick
  /// @return fee The last pool fee value in hundredths of a bip, i.e. 1e-6
  /// @return timepointIndex The index of the last written timepoint
  /// @return communityFee The community fee percentage of the swap fee in thousandths (1e-3)
  /// @return unlocked Whether the pool is currently locked to reentrancy
  function globalState()
    external
    view
    returns (uint160 price, int24 tick, int24 prevInitializedTick, uint16 fee, uint16 timepointIndex, uint8 communityFee, bool unlocked);

  /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
  /// @dev This value can overflow the uint256
  function totalFeeGrowth0Token() external view returns (uint256);

  /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
  /// @dev This value can overflow the uint256
  function totalFeeGrowth1Token() external view returns (uint256);

  /// @notice The currently in range liquidity available to the pool
  /// @dev This value has no relationship to the total liquidity across all ticks.
  /// Returned value cannot exceed type(uint128).max
  function liquidity() external view returns (uint128);

  /// @notice The current tick spacing
  /// @dev Ticks can only be used at multiples of this value
  /// e.g.: a tickSpacing of 60 means ticks can be initialized every 60th tick, i.e., ..., -120, -60, 0, 60, 120, ...
  /// This value is an int24 to avoid casting even though it is always positive.
  /// @return The current tick spacing
  function tickSpacing() external view returns (int24);

  /// @notice The current tick spacing for limit orders
  /// @dev Ticks can only be used for limit orders at multiples of this value
  /// This value is an int24 to avoid casting even though it is always positive.
  /// @return The current tick spacing for limit orders
  function tickSpacingLimitOrders() external view returns (int24);

  /// @notice The timestamp of the last sending of tokens to community vault
  function communityFeeLastTimestamp() external view returns (uint32);

  /// @notice The amounts of token0 and token1 that will be sent to the vault
  /// @dev Will be sent COMMUNITY_FEE_TRANSFER_FREQUENCY after communityFeeLastTimestamp
  function getCommunityFeePending() external view returns (uint128 communityFeePending0, uint128 communityFeePending1);

  /// @notice The tracked token0 and token1 reserves of pool
  /// @dev If at any time the real balance is larger, the excess will be transferred to liquidity providers as additional fee.
  /// If the balance exceeds uint128, the excess will be sent to the communityVault.
  function getReserves() external view returns (uint128 reserve0, uint128 reserve1);

  /// @notice The accumulator of seconds per liquidity since the pool was first initialized
  function secondsPerLiquidityCumulative() external view returns (uint160);

  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityTotal The total amount of position liquidity that uses the pool either as tick lower or tick upper
  /// @return liquidityDelta How much liquidity changes when the pool price crosses the tick
  /// @return outerFeeGrowth0Token The fee growth on the other side of the tick from the current tick in token0
  /// @return outerFeeGrowth1Token The fee growth on the other side of the tick from the current tick in token1
  /// @return prevTick The previous tick in tick list
  /// @return nextTick The next tick in tick list
  /// @return outerSecondsPerLiquidity The seconds spent per liquidity on the other side of the tick from the current tick
  /// @return outerSecondsSpent The seconds spent on the other side of the tick from the current tick
  /// @return hasLimitOrders Whether there are limit orders on this tick or not
  /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
  /// a specific position.
  function ticks(
    int24 tick
  )
    external
    view
    returns (
      uint128 liquidityTotal,
      int128 liquidityDelta,
      uint256 outerFeeGrowth0Token,
      uint256 outerFeeGrowth1Token,
      int24 prevTick,
      int24 nextTick,
      uint160 outerSecondsPerLiquidity,
      uint32 outerSecondsSpent,
      bool hasLimitOrders
    );

  /// @notice Returns the summary information about a limit orders at tick
  /// @param tick The tick to look up
  /// @return amountToSell The amount of tokens to sell. Has only relative meaning
  /// @return soldAmount The amount of tokens already sold. Has only relative meaning
  /// @return boughtAmount0Cumulative The accumulator of bought tokens0 per amountToSell. Has only relative meaning
  /// @return boughtAmount1Cumulative The accumulator of bought tokens1 per amountToSell. Has only relative meaning
  /// @return initialized Will be true if a limit order was created at least once on this tick
  function limitOrders(
    int24 tick
  )
    external
    view
    returns (uint128 amountToSell, uint128 soldAmount, uint256 boughtAmount0Cumulative, uint256 boughtAmount1Cumulative, bool initialized);

  /// @notice Returns 256 packed tick initialized boolean values. See TickTree for more information
  function tickTable(int16 wordPosition) external view returns (uint256);

  /// @notice Returns the information about a position by the position's key
  /// @param key The position's key is a hash of a preimage composed by the owner, bottomTick and topTick
  /// @return liquidity The amount of liquidity in the position
  /// @return innerFeeGrowth0Token Fee growth of token0 inside the tick range as of the last mint/burn/poke
  /// @return innerFeeGrowth1Token Fee growth of token1 inside the tick range as of the last mint/burn/poke
  /// @return fees0 The computed amount of token0 owed to the position as of the last mint/burn/poke
  /// @return fees1 The computed amount of token1 owed to the position as of the last mint/burn/poke
  function positions(
    bytes32 key
  ) external view returns (uint256 liquidity, uint256 innerFeeGrowth0Token, uint256 innerFeeGrowth1Token, uint128 fees0, uint128 fees1);

  /// @notice Returns the information about active incentive
  /// @dev if there is no active incentive at the moment, incentiveAddress would be equal to address(0)
  /// @return incentiveAddress The address associated with the current active incentive
  function activeIncentive() external view returns (address incentiveAddress);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolDerivedState {
  /// @notice Returns a snapshot of seconds per liquidity and seconds inside a tick range
  /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
  /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
  /// snapshot is taken and the second snapshot is taken.
  /// @param bottomTick The lower tick of the range
  /// @param topTick The upper tick of the range
  /// @return innerSecondsSpentPerLiquidity The snapshot of seconds per liquidity for the range
  /// @return innerSecondsSpent The snapshot of the number of seconds during which the price was in this range
  function getInnerCumulatives(
    int24 bottomTick,
    int24 topTick
  ) external view returns (uint160 innerSecondsSpentPerLiquidity, uint32 innerSecondsSpent);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolActions {
  /// @notice Sets the initial price for the pool
  /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
  /// @dev Initialization should be done in one transaction with pool creation to avoid front-running
  /// @param price the initial sqrt price of the pool as a Q64.96
  function initialize(uint160 price) external;

  /// @notice Adds liquidity for the given recipient/bottomTick/topTick position
  /// @dev The caller of this method receives a callback in the form of IAlgebraMintCallback# AlgebraMintCallback
  /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
  /// on bottomTick, topTick, the amount of liquidity, and the current price. If bottomTick == topTick position is treated as a limit order
  /// @param sender The address which will receive potential surplus of paid tokens
  /// @param recipient The address for which the liquidity will be created
  /// @param bottomTick The lower tick of the position in which to add liquidity
  /// @param topTick The upper tick of the position in which to add liquidity
  /// @param amount The desired amount of liquidity to mint
  /// @param data Any data that should be passed through to the callback
  /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
  /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
  /// @return liquidityActual The actual minted amount of liquidity
  function mint(
    address sender,
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount,
    bytes calldata data
  ) external returns (uint256 amount0, uint256 amount1, uint128 liquidityActual);

  /// @notice Collects tokens owed to a position
  /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
  /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
  /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
  /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
  /// @param recipient The address which should receive the fees collected
  /// @param bottomTick The lower tick of the position for which to collect fees
  /// @param topTick The upper tick of the position for which to collect fees
  /// @param amount0Requested How much token0 should be withdrawn from the fees owed
  /// @param amount1Requested How much token1 should be withdrawn from the fees owed
  /// @return amount0 The amount of fees collected in token0
  /// @return amount1 The amount of fees collected in token1
  function collect(
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);

  /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
  /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
  /// @dev Fees must be collected separately via a call to #collect
  /// @param bottomTick The lower tick of the position for which to burn liquidity
  /// @param topTick The upper tick of the position for which to burn liquidity
  /// @param amount How much liquidity to burn
  /// @return amount0 The amount of token0 sent to the recipient
  /// @return amount1 The amount of token1 sent to the recipient
  function burn(int24 bottomTick, int24 topTick, uint128 amount) external returns (uint256 amount0, uint256 amount1);

  /// @notice Swap token0 for token1, or token1 for token0
  /// @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback#AlgebraSwapCallback
  /// @param recipient The address to receive the output of the swap
  /// @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @param amountRequired The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
  /// @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
  /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
  /// @param data Any data to be passed through to the callback. If using the Router it should contain SwapRouter#SwapCallbackData
  /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
  /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
  function swap(
    address recipient,
    bool zeroToOne,
    int256 amountRequired,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /// @notice Swap token0 for token1, or token1 for token0 (tokens that have fee on transfer)
  /// @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback#AlgebraSwapCallback
  /// @param sender The address called this function (Comes from the Router)
  /// @param recipient The address to receive the output of the swap
  /// @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @param amountRequired The amount of the swap, which implicitly configures the swap as exact input
  /// @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
  /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
  /// @param data Any data to be passed through to the callback. If using the Router it should contain SwapRouter#SwapCallbackData
  /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
  /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
  function swapSupportingFeeOnInputTokens(
    address sender,
    address recipient,
    bool zeroToOne,
    int256 amountRequired,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
  /// @dev The caller of this method receives a callback in the form of IAlgebraFlashCallback#AlgebraFlashCallback
  /// @dev All excess tokens paid in the callback are distributed to currently in-range liquidity providers as an additional fee.
  /// If there are no in-range liquidity providers, the fee will be transferred to the first active provider in the future
  /// @param recipient The address which will receive the token0 and token1 amounts
  /// @param amount0 The amount of token0 to send
  /// @param amount1 The amount of token1 to send
  /// @param data Any data to be passed through to the callback
  function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by permissioned addresses
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolPermissionedActions {
  /// @notice Set the community's % share of the fees. Cannot exceed 25% (250). Only factory owner or POOLS_ADMINISTRATOR_ROLE role
  /// @param communityFee new community fee percent in thousandths (1e-3)
  function setCommunityFee(uint8 communityFee) external;

  /// @notice Set the new tick spacing values. Only factory owner or POOLS_ADMINISTRATOR_ROLE role
  /// @param newTickSpacing The new tick spacing value
  /// @param newTickSpacingLimitOrders The new tick spacing value for limit orders
  function setTickSpacing(int24 newTickSpacing, int24 newTickSpacingLimitOrders) external;

  /// @notice Sets an active incentive. Only farming
  /// @param newIncentiveAddress The address associated with the incentive
  function setIncentive(address newIncentiveAddress) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolEvents {
  /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
  /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
  /// @param price The initial sqrt price of the pool, as a Q64.96
  /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
  event Initialize(uint160 price, int24 tick);

  /// @notice Emitted when liquidity is minted for a given position
  /// @dev If the top and bottom ticks match, this should be treated as a limit order
  /// @param sender The address that minted the liquidity
  /// @param owner The owner of the position and recipient of any minted liquidity
  /// @param bottomTick The lower tick of the position
  /// @param topTick The upper tick of the position
  /// @param liquidityAmount The amount of liquidity minted to the position range
  /// @param amount0 How much token0 was required for the minted liquidity
  /// @param amount1 How much token1 was required for the minted liquidity
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed bottomTick,
    int24 indexed topTick,
    uint128 liquidityAmount,
    uint256 amount0,
    uint256 amount1
  );

  /// @notice Emitted when fees are collected by the owner of a position
  /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
  /// @param owner The owner of the position for which fees are collected
  /// @param recipient The address that received fees
  /// @param bottomTick The lower tick of the position
  /// @param topTick The upper tick of the position
  /// @param amount0 The amount of token0 fees collected
  /// @param amount1 The amount of token1 fees collected
  event Collect(address indexed owner, address recipient, int24 indexed bottomTick, int24 indexed topTick, uint128 amount0, uint128 amount1);

  /// @notice Emitted when a position's liquidity is removed
  /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
  /// @param owner The owner of the position for which liquidity is removed
  /// @param bottomTick The lower tick of the position
  /// @param topTick The upper tick of the position
  /// @param liquidityAmount The amount of liquidity to remove
  /// @param amount0 The amount of token0 withdrawn
  /// @param amount1 The amount of token1 withdrawn
  event Burn(address indexed owner, int24 indexed bottomTick, int24 indexed topTick, uint128 liquidityAmount, uint256 amount0, uint256 amount1);

  /// @notice Emitted by the pool for any swaps between token0 and token1
  /// @param sender The address that initiated the swap call, and that received the callback
  /// @param recipient The address that received the output of the swap
  /// @param amount0 The delta of the token0 balance of the pool
  /// @param amount1 The delta of the token1 balance of the pool
  /// @param price The sqrt(price) of the pool after the swap, as a Q64.96
  /// @param liquidity The liquidity of the pool after the swap
  /// @param tick The log base 1.0001 of price of the pool after the swap
  event Swap(address indexed sender, address indexed recipient, int256 amount0, int256 amount1, uint160 price, uint128 liquidity, int24 tick);

  /// @notice Emitted by the pool for any flashes of token0/token1
  /// @param sender The address that initiated the swap call, and that received the callback
  /// @param recipient The address that received the tokens from flash
  /// @param amount0 The amount of token0 that was flashed
  /// @param amount1 The amount of token1 that was flashed
  /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
  /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
  event Flash(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1, uint256 paid0, uint256 paid1);

  /// @notice Emitted when the community fee is changed by the pool
  /// @param communityFeeNew The updated value of the community fee in thousandths (1e-3)
  event CommunityFee(uint8 communityFeeNew);

  /// @notice Emitted when the tick spacing changes
  /// @param newTickSpacing The updated value of the new tick spacing
  /// @param newTickSpacingLimitOrders The updated value of the new tick spacing for limit orders
  event TickSpacing(int24 newTickSpacing, int24 newTickSpacingLimitOrders);

  /// @notice Emitted when new activeIncentive is set
  /// @param newIncentiveAddress The address of the new incentive
  event Incentive(address indexed newIncentiveAddress);

  /// @notice Emitted when the fee changes inside the pool
  /// @param fee The current fee in hundredths of a bip, i.e. 1e-6
  event Fee(uint16 fee);

  /// @notice Emitted in case of an error when trying to write to the DataStorage
  /// @dev This shouldn't happen
  event DataStorageFailure();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes Algebra Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain separator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of NativeToken
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WNativeToken balance and sends it to recipient as NativeToken.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WNativeToken from users.
    /// @param amountMinimum The minimum amount of WNativeToken to unwrap
    /// @param recipient The address receiving NativeToken
    function unwrapWNativeToken(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any NativeToken balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundNativeToken() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface IPeripheryImmutableState {
    /// @return Returns the address of the Algebra factory
    function factory() external view returns (address);

    /// @return Returns the address of the pool Deployer
    function poolDeployer() external view returns (address);

    /// @return Returns the address of WNativeToken
    function WNativeToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the poolDeployer and tokens
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xa360004fb86ddf4cd7fe9aa67d0c6a7f7812d9069142659003dc503e1d7d241f;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
    }

    /// @notice Returns PoolKey: the ordered tokens
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(address tokenA, address tokenB) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB});
    }

    /// @notice Deterministically computes the pool address given the poolDeployer and PoolKey
    /// @param poolDeployer The Algebra poolDeployer contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the Algebra pool
    function computeAddress(address poolDeployer, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1, 'Invalid order of tokens');
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            poolDeployer,
                            keccak256(abi.encode(key.token0, key.token1)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/IERC4626Minimal.sol";
import "./SuperAdminControl.sol";

abstract contract ApyFlowVault is IERC4626Minimal, ERC20, ERC165, SuperAdminControl {
    using SafeERC20 for IERC20Metadata;
    using Math for uint256;

    IERC20Metadata internal immutable _asset;
    uint8 private immutable _decimals;

    constructor(IERC20Metadata asset_) {
        _asset = asset_;
        _decimals = asset_.decimals();
    }

    function decimals() public view override(ERC20, IERC20Metadata) returns (uint8) {
        return _decimals;
    }

    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    function _totalAssets() internal view virtual returns (uint256);

    function totalAssets() public view override returns (uint256) {
        return _totalAssets() + _asset.balanceOf(address(this));
    }

    function _convertToAssets(uint256 shares, uint256 totalAssets_, uint256 totalSupply_)
        internal
        pure
        returns (uint256 assets)
    {
        return ((totalSupply_ == 0) || (totalAssets_ == 0)) ? shares : shares.mulDiv(totalAssets_, totalSupply_);
    }

    function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
        return _convertToAssets(shares, totalAssets(), totalSupply());
    }

    function _convertToShares(uint256 assets, uint256 totalAssets_, uint256 totalSupply_)
        internal
        pure
        returns (uint256 shares)
    {
        return ((totalSupply_ == 0) || (totalAssets_ == 0)) ? assets : assets.mulDiv(totalSupply_, totalAssets_);
    }

    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        return _convertToShares(assets, totalAssets(), totalSupply());
    }

    function pricePerToken() public view returns (uint256) {
        return convertToAssets(10 ** decimals());
    }

    function _deposit(uint256 assets) internal virtual;

    function deposit(uint256 assets, address receiver) public virtual override returns (uint256 shares) {
        if (assets == 0) {
            return 0;
        }
        uint256 totalAssetsBefore = totalAssets();
        _asset.safeTransferFrom(_msgSender(), address(this), assets);
        _deposit(assets);
        uint256 totalAssetsAfter = totalAssets();
        shares = _convertToShares(totalAssetsAfter - totalAssetsBefore, totalAssetsBefore, totalSupply());
        _mint(receiver, shares);

        emit Deposit(_msgSender(), receiver, assets, shares);
    }

    function _redeem(uint256 shares) internal virtual returns (uint256 assets);

    function _performRedeem(uint256 shares) internal virtual returns (uint256 assets) {
        assets = _asset.balanceOf(address(this)).mulDiv(shares, totalSupply());
        assets += _redeem(shares);
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual override returns (uint256 assets) {
        if (_msgSender() != owner) {
            _spendAllowance(owner, _msgSender(), shares);
        }

        assets = _performRedeem(shares);
        _burn(owner, shares);
        _asset.safeTransfer(receiver, assets);

        emit Withdraw(_msgSender(), receiver, owner, assets, shares);
    }

    function previewRedeemHelper(uint256 shares) external {
        require(msg.sender == address(this));
        uint256 assets = _performRedeem(shares);
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, assets)
            revert(ptr, 32)
        }
    }

    function previewRedeem(uint256 shares) external returns (uint256 assets) {
        try this.previewRedeemHelper(shares) {}
        catch (bytes memory reason) {
            if (reason.length != 32) {
                if (reason.length < 68) revert("Unexpected error");
                assembly {
                    reason := add(reason, 0x04)
                }
                revert(abi.decode(reason, (string)));
            }
            return abi.decode(reason, (uint256));
        }
    }
}

pragma solidity 0.8.19;

interface IHarvestableApyFlowVault {
    function harvest() external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IERC4626Minimal is IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SuperAdminControl is Ownable {
    struct CallData {
        address to;
        bytes data;
        uint256 value;
    }

    function call(CallData[] calldata calls) external onlyOwner {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success,) = calls[i].to.call{value: calls[i].value}(calls[i].data);
            require(success, "failed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}