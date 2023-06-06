// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../IAdapter.sol";
import "../../lib/aave-v3/AaveV3.sol";
import "../../lib/augustus-rfq/AugustusRFQ.sol";
import "../../lib/uniswapv2/dystopia/DystopiaUniswapV2Fork.sol";
import "../../lib/woofi-v2/WooFiV2Adapter.sol";
import "../../lib/jarvis-v6/JarvisV6.sol";
import "../../lib/swaap-v1/SwaapV1.sol";
import "../../lib/hashflow/HashFlow.sol";
import "../../lib/swaap-v2/SwaapV2.sol";

/*
 * @dev This contract will route calls to dexes according to the following indexing:
 * 1- AaveV3
 * 2- AugustusRFQ
 * 3- DystopiaUniswapV2Fork
 * 4- WooFiV2
 * 5- JarvisV6
 * 6- SwaapV1
 * 7 - HashFlow
 * 8 - SwaapV2
 */
contract PolygonAdapter02 is
    IAdapter,
    AaveV3,
    AugustusRFQ,
    DystopiaUniswapV2Fork,
    WooFiV2Adapter,
    JarvisV6,
    SwaapV1,
    HashFlow,
    SwaapV2
{
    using SafeMath for uint256;

    /*solhint-disable no-empty-blocks*/
    constructor(
        address _weth,
        uint16 _aaveV3RefCode,
        address _aaveV3Pool,
        address _aaveV3WethGateway
    ) public WethProvider(_weth) AaveV3(_aaveV3RefCode, _aaveV3Pool, _aaveV3WethGateway) {}

    /*solhint-enable no-empty-blocks*/

    function initialize(bytes calldata) external override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256,
        Utils.Route[] calldata route
    ) external payable override {
        for (uint256 i = 0; i < route.length; i++) {
            if (route[i].index == 1) {
                swapOnAaveV3(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000), route[i].payload);
            } else if (route[i].index == 2) {
                //swap on augustusRFQ
                swapOnAugustusRFQ(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 3) {
                swapOnDystopiaUniswapV2Fork(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].payload
                );
            } else if (route[i].index == 4) {
                swapOnWooFiV2(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 5) {
                swapOnJarvisV6(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if (route[i].index == 6) {
                swapOnSwaapV1(fromToken, toToken, fromAmount.mul(route[i].percent).div(10000), route[i].targetExchange);
            } else if (route[i].index == 7) {
                // swap on HashFlow
                swapOnHashFlow(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else if(route[i].index == 8) {
                swapOnSwaapV2(
                    fromToken,
                    toToken,
                    fromAmount.mul(route[i].percent).div(10000),
                    route[i].targetExchange,
                    route[i].payload
                );
            } else {
                revert("Index not supported");
            }
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../lib/Utils.sol";

interface IAdapter {
    /**
     * @dev Certain adapters needs to be initialized.
     * This method will be called from Augustus
     */
    function initialize(bytes calldata data) external;

    /**
     * @dev The function which performs the swap on an exchange.
     * @param fromToken Address of the source token
     * @param toToken Address of the destination token
     * @param fromAmount Amount of source tokens to be swapped
     * @param networkFee NOT USED - Network fee to be used in this router
     * @param route Route to be followed
     */
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 networkFee,
        Utils.Route[] calldata route
    ) external payable;
}

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../Utils.sol";

import "../../AugustusStorage.sol";

interface IAaveV3WETHGateway {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address pool,
        uint256 amount,
        address onBehalfOf
    ) external;
}

interface IAaveV3Pool {
    function supply(
        IERC20 asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        IERC20 asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

contract AaveV3 {
    struct AaveData {
        address aToken;
    }

    uint16 public immutable aaveV3RefCode;
    address public immutable aaveV3Pool;
    address public immutable aaveV3WethGateway;

    constructor(
        uint16 _refCode,
        address _pool,
        address _wethGateway
    ) public {
        aaveV3RefCode = _refCode;
        aaveV3Pool = _pool;
        aaveV3WethGateway = _wethGateway;
    }

    function swapOnAaveV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        _swapOnAaveV3(fromToken, toToken, fromAmount, payload);
    }

    function buyOnAaveV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        _swapOnAaveV3(fromToken, toToken, fromAmount, payload);
    }

    function _swapOnAaveV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes memory payload
    ) private {
        AaveData memory data = abi.decode(payload, (AaveData));

        if (address(fromToken) == address(data.aToken)) {
            if (address(toToken) == Utils.ethAddress()) {
                Utils.approve(aaveV3WethGateway, address(fromToken), fromAmount);
                IAaveV3WETHGateway(aaveV3WethGateway).withdrawETH(aaveV3Pool, fromAmount, address(this));
            } else {
                Utils.approve(aaveV3Pool, address(fromToken), fromAmount);
                IAaveV3Pool(aaveV3Pool).withdraw(toToken, fromAmount, address(this));
            }
        } else if (address(toToken) == address(data.aToken)) {
            if (address(fromToken) == Utils.ethAddress()) {
                IAaveV3WETHGateway(aaveV3WethGateway).depositETH{ value: fromAmount }(
                    aaveV3Pool,
                    address(this),
                    aaveV3RefCode
                );
            } else {
                Utils.approve(aaveV3Pool, address(fromToken), fromAmount);
                IAaveV3Pool(aaveV3Pool).supply(fromToken, fromAmount, address(this), aaveV3RefCode);
            }
        } else {
            revert("Invalid aToken");
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IAugustusRFQ.sol";
import "../Utils.sol";
import "../WethProvider.sol";
import "../weth/IWETH.sol";

abstract contract AugustusRFQ is WethProvider {
    using SafeMath for uint256;

    struct AugustusRFQData {
        IAugustusRFQ.OrderInfo[] orderInfos;
    }

    function swapOnAugustusRFQ(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        AugustusRFQData memory data = abi.decode(payload, (AugustusRFQData));

        for (uint256 i = 0; i < data.orderInfos.length; ++i) {
            address userAddress = address(uint160(data.orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
            Utils.approve(exchange, WETH, fromAmount);
        } else {
            Utils.approve(exchange, address(fromToken), fromAmount);
        }

        IAugustusRFQ(exchange).tryBatchFillOrderTakerAmount(data.orderInfos, fromAmount, address(this));

        if (address(toToken) == Utils.ethAddress()) {
            uint256 amount = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(amount);
        }
    }

    function buyOnAugustusRFQ(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmountMax,
        uint256 toAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        AugustusRFQData memory data = abi.decode(payload, (AugustusRFQData));

        for (uint256 i = 0; i < data.orderInfos.length; ++i) {
            address userAddress = address(uint160(data.orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmountMax }();
            Utils.approve(exchange, WETH, fromAmountMax);
        } else {
            Utils.approve(exchange, address(fromToken), fromAmountMax);
        }

        IAugustusRFQ(exchange).tryBatchFillOrderMakerAmount(data.orderInfos, toAmount, address(this));

        if (address(fromToken) == Utils.ethAddress() || address(toToken) == Utils.ethAddress()) {
            uint256 amount = IERC20(WETH).balanceOf(address(this));
            IWETH(WETH).withdraw(amount);
        }
    }
}

// SPDX-License-Identifier: ISC
pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "../../Utils.sol";
import "../../weth/IWETH.sol";
import "./IDystPair.sol";

abstract contract DystopiaUniswapV2Fork {
    using SafeMath for uint256;

    // Pool bits are 255-161: fee, 160: direction flag, 159-0: address
    uint256 constant DYSTOPIA_FEE_OFFSET = 161;
    uint256 constant DYSTOPIA_DIRECTION_FLAG = 0x0000000000000000000000010000000000000000000000000000000000000000;

    struct DystopiaUniswapV2Data {
        address weth;
        uint256[] pools;
        bool isFeeTokenInRoute;
    }

    function swapOnDystopiaUniswapV2Fork(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        bytes calldata payload
    ) internal {
        DystopiaUniswapV2Data memory data = abi.decode(payload, (DystopiaUniswapV2Data));
        if (data.isFeeTokenInRoute) {
            _swapOnDystopiaUniswapV2ForkWithTransferFee(address(fromToken), fromAmount, data.weth, data.pools);
        } else {
            _swapOnDystopiaUniswapV2Fork(address(fromToken), fromAmount, data.weth, data.pools);
        }
    }

    function _swapOnDystopiaUniswapV2ForkWithTransferFee(
        address tokenIn,
        uint256 amountIn,
        address weth,
        uint256[] memory pools
    ) private returns (uint256 tokensBought) {
        uint256 pairs = pools.length;

        require(pairs != 0, "At least one pool required");

        bool tokensBoughtEth;

        uint256 balanceBeforeTransfer;
        if (tokenIn == Utils.ethAddress()) {
            balanceBeforeTransfer = Utils.tokenBalance(weth, address(pools[0]));
            IWETH(weth).deposit{ value: amountIn }();
            require(IWETH(weth).transfer(address(pools[0]), amountIn));
            tokensBought = Utils.tokenBalance(weth, address(pools[0])) - balanceBeforeTransfer;
        } else {
            balanceBeforeTransfer = Utils.tokenBalance(tokenIn, address(pools[0]));
            TransferHelper.safeTransfer(tokenIn, address(pools[0]), amountIn);
            tokensBoughtEth = weth != address(0);
            tokensBought = Utils.tokenBalance(tokenIn, address(pools[0])) - balanceBeforeTransfer;
        }

        for (uint256 i = 0; i < pairs; ++i) {
            uint256 p = pools[i];
            address pool = address(p);
            bool direction = p & DYSTOPIA_DIRECTION_FLAG == 0;

            address to;
            address _nextTokenIn;

            if (i + 1 == pairs) {
                to = address(this);
                _nextTokenIn = pools[i] & DYSTOPIA_DIRECTION_FLAG == 0
                    ? IDystPair(pool).token1()
                    : IDystPair(pool).token0();
            } else {
                to = address(pools[i + 1]);
                _nextTokenIn = pools[i + 1] & DYSTOPIA_DIRECTION_FLAG == 0
                    ? IDystPair(pool).token0()
                    : IDystPair(pool).token1();
            }

            tokensBought = IDystPair(pool).getAmountOut(
                tokensBought,
                direction ? IDystPair(pool).token0() : IDystPair(pool).token1()
            );

            (uint256 amount0Out, uint256 amount1Out) = direction
                ? (uint256(0), tokensBought)
                : (tokensBought, uint256(0));

            balanceBeforeTransfer = Utils.tokenBalance(_nextTokenIn, to);
            IDystPair(pool).swap(amount0Out, amount1Out, to, "");
            tokensBought = Utils.tokenBalance(_nextTokenIn, to) - balanceBeforeTransfer;
        }

        if (tokensBoughtEth) {
            IWETH(weth).withdraw(tokensBought);
        }
    }

    function _swapOnDystopiaUniswapV2Fork(
        address tokenIn,
        uint256 amountIn,
        address weth,
        uint256[] memory pools
    ) private returns (uint256 tokensBought) {
        uint256 pairs = pools.length;

        require(pairs != 0, "At least one pool required");

        bool tokensBoughtEth;

        if (tokenIn == Utils.ethAddress()) {
            IWETH(weth).deposit{ value: amountIn }();
            require(IWETH(weth).transfer(address(pools[0]), amountIn));
        } else {
            TransferHelper.safeTransfer(tokenIn, address(pools[0]), amountIn);
            tokensBoughtEth = weth != address(0);
        }

        tokensBought = amountIn;

        for (uint256 i = 0; i < pairs; ++i) {
            uint256 p = pools[i];
            address pool = address(p);
            bool direction = p & DYSTOPIA_DIRECTION_FLAG == 0;

            tokensBought = IDystPair(pool).getAmountOut(
                tokensBought,
                direction ? IDystPair(pool).token0() : IDystPair(pool).token1()
            );

            if (IDystPair(pool).stable()) {
                tokensBought = tokensBought.sub(100); // deduce 100wei to mitigate stable swap's K miscalculations
            }

            (uint256 amount0Out, uint256 amount1Out) = direction
                ? (uint256(0), tokensBought)
                : (tokensBought, uint256(0));
            IDystPair(pool).swap(amount0Out, amount1Out, i + 1 == pairs ? address(this) : address(pools[i + 1]), "");
        }

        if (tokensBoughtEth) {
            IWETH(weth).withdraw(tokensBought);
        }
    }
}

// SPDX-License-Identifier: ISC
pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../WethProvider.sol";
import "../Utils.sol";
import "../weth/IWETH.sol";

interface IWooPPV2 {
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address to,
        address rebateTo
    ) external returns (uint256 realToAmount);
}

abstract contract WooFiV2Adapter is WethProvider {
    using SafeERC20 for IERC20;

    struct WooFiV2Data {
        address rebateTo;
    }

    function swapOnWooFiV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        WooFiV2Data memory wooFiV2Data = abi.decode(payload, (WooFiV2Data));

        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        IERC20(_fromToken).safeTransfer(exchange, fromAmount);

        IWooPPV2(exchange).swap(_fromToken, _toToken, fromAmount, 1, address(this), wooFiV2Data.rebateTo);

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";

interface IJarvisPool {
    struct MintParams {
        // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
        uint256 minNumTokens;
        // Amount of collateral that a user wants to spend for minting
        uint256 collateralAmount;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send synthetic tokens minted
        address recipient;
    }

    struct RedeemParams {
        // Amount of synthetic tokens that user wants to use for redeeming
        uint256 numTokens;
        // Minimium amount of collateral that user wants to redeem (anti-slippage)
        uint256 minCollateral;
        // Expiration time of the transaction
        uint256 expiration;
        // Address to which send collateral tokens redeemed
        address recipient;
    }

    function mint(MintParams memory mintParams) external returns (uint256 syntheticTokensMinted, uint256 feePaid);

    function redeem(RedeemParams memory redeemParams) external returns (uint256 collateralRedeemed, uint256 feePaid);
}

contract JarvisV6 {
    enum MethodType {
        mint,
        redeem
    }

    struct JarvisV6Data {
        uint256 opType;
        uint128 expiration;
    }

    function swapOnJarvisV6(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        JarvisV6Data memory data = abi.decode(payload, (JarvisV6Data));
        Utils.approve(exchange, address(fromToken), fromAmount);

        if (data.opType == uint256(MethodType.mint)) {
            IJarvisPool.MintParams memory mintParam = IJarvisPool.MintParams(
                1,
                fromAmount,
                data.expiration,
                address(this)
            );

            IJarvisPool(exchange).mint(mintParam);
        } else if (data.opType == uint256(MethodType.redeem)) {
            IJarvisPool.RedeemParams memory redeemParam = IJarvisPool.RedeemParams(
                fromAmount,
                1,
                data.expiration,
                address(this)
            );

            IJarvisPool(exchange).redeem(redeemParam);
        } else {
            revert("Invalid opType");
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPoolSwapSwaapV1.sol";
import "../Utils.sol";
import "../weth/IWETH.sol";
import "../WethProvider.sol";

abstract contract SwaapV1 is WethProvider {
    function swapOnSwaapV1(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange
    ) internal {
        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        IPoolSwapSwaapV1(exchange).swapExactAmountInMMM(_fromToken, fromAmount, _toToken, 1, type(uint256).max);

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }

    function buyOnSwaapV1(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchange
    ) internal {
        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        IPoolSwapSwaapV1(exchange).swapExactAmountOutMMM(_fromToken, fromAmount, _toToken, toAmount, type(uint256).max);

        if (address(fromToken) == Utils.ethAddress() || address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }
}

// SPDX-License-Identifier: ISC
pragma solidity 0.7.5;
pragma abicoder v2;

import "../Utils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IQuote {
    struct RFQTQuote {
        address pool;
        address externalAccount;
        address trader;
        address effectiveTrader;
        address baseToken;
        address quoteToken;
        uint256 effectiveBaseTokenAmount;
        uint256 maxBaseTokenAmount;
        uint256 maxQuoteTokenAmount;
        uint256 quoteExpiry;
        uint256 nonce;
        bytes32 txid;
        bytes signature;
    }
}

interface IHashFlowRouter {
    function tradeSingleHop(IQuote.RFQTQuote calldata quote) external payable;
}

contract HashFlow {
    struct HashFlowData {
        address pool;
        address quoteToken;
        address externalAccount;
        uint256 baseTokenAmount;
        uint256 quoteTokenAmount;
        uint256 quoteExpiry;
        uint256 nonce;
        bytes32 txid;
        bytes signature;
    }

    function buyOnHashFlow(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 maxFromAmount,
        uint256 toAmount,
        address targetExchange,
        bytes calldata payload
    ) internal {
        HashFlowData memory data = abi.decode(payload, (HashFlowData));

        require(data.baseTokenAmount <= maxFromAmount, "HashFlow baseTokenAmount > maxFromAmount");
        require(data.quoteTokenAmount >= toAmount, "HashFlow quoteTokenAmount < toAmount");

        if (address(fromToken) == Utils.ethAddress()) {
            IHashFlowRouter(targetExchange).tradeSingleHop{ value: data.baseTokenAmount }(
                IQuote.RFQTQuote({
                    pool: data.pool,
                    externalAccount: data.externalAccount,
                    trader: address(this),
                    effectiveTrader: msg.sender,
                    baseToken: address(0),
                    quoteToken: address(toToken),
                    effectiveBaseTokenAmount: data.baseTokenAmount,
                    maxBaseTokenAmount: data.baseTokenAmount,
                    maxQuoteTokenAmount: data.quoteTokenAmount,
                    quoteExpiry: data.quoteExpiry,
                    nonce: data.nonce,
                    txid: data.txid,
                    signature: data.signature
                })
            );
        } else {
            Utils.approve(targetExchange, address(fromToken), data.baseTokenAmount);

            IHashFlowRouter(targetExchange).tradeSingleHop(
                IQuote.RFQTQuote({
                    pool: data.pool,
                    externalAccount: data.externalAccount,
                    trader: address(this),
                    effectiveTrader: msg.sender,
                    baseToken: address(fromToken),
                    quoteToken: data.quoteToken,
                    effectiveBaseTokenAmount: data.baseTokenAmount,
                    maxBaseTokenAmount: data.baseTokenAmount,
                    maxQuoteTokenAmount: data.quoteTokenAmount,
                    quoteExpiry: data.quoteExpiry,
                    nonce: data.nonce,
                    txid: data.txid,
                    signature: data.signature
                })
            );
        }
    }

    function swapOnHashFlow(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        HashFlowData memory data = abi.decode(payload, (HashFlowData));

        require(data.baseTokenAmount <= fromAmount, "HashFlow baseTokenAmount > fromAmount");

        if (address(fromToken) == Utils.ethAddress()) {
            IHashFlowRouter(exchange).tradeSingleHop{ value: data.baseTokenAmount }(
                IQuote.RFQTQuote({
                    pool: data.pool,
                    externalAccount: data.externalAccount,
                    trader: address(this),
                    effectiveTrader: msg.sender,
                    baseToken: address(0),
                    quoteToken: address(toToken),
                    effectiveBaseTokenAmount: data.baseTokenAmount,
                    maxBaseTokenAmount: data.baseTokenAmount,
                    maxQuoteTokenAmount: data.quoteTokenAmount,
                    quoteExpiry: data.quoteExpiry,
                    nonce: data.nonce,
                    txid: data.txid,
                    signature: data.signature
                })
            );
        } else {
            Utils.approve(exchange, address(fromToken), data.baseTokenAmount);

            IHashFlowRouter(exchange).tradeSingleHop(
                IQuote.RFQTQuote({
                    pool: data.pool,
                    externalAccount: data.externalAccount,
                    trader: address(this),
                    effectiveTrader: msg.sender,
                    baseToken: address(fromToken),
                    quoteToken: data.quoteToken,
                    effectiveBaseTokenAmount: data.baseTokenAmount,
                    maxBaseTokenAmount: data.baseTokenAmount,
                    maxQuoteTokenAmount: data.quoteTokenAmount,
                    quoteExpiry: data.quoteExpiry,
                    nonce: data.nonce,
                    txid: data.txid,
                    signature: data.signature
                })
            );
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../Utils.sol";
import "../balancerv2/IBalancerV2Vault.sol";

contract SwaapV2 {
    using SafeMath for uint256;

    struct BalancerBatchData {
        IBalancerV2Vault.BatchSwapStep[] swaps;
        address[] assets;
        IBalancerV2Vault.FundManagement funds;
        int256[] limits;
    }

    struct BalancerSimpleData {
        IBalancerV2Vault.SingleSwap singleSwap;
        IBalancerV2Vault.FundManagement funds;
        uint256 limit;
    }

    function substituteCallerOrigin(bytes memory swapUserData, uint256 memorySlot) public view {
        if(swapUserData.length >= memorySlot.add(32)) {
            assembly {
                let swapUserDataPtr := add(swapUserData, 0x20) // first 32 bytes corresponds to length
                let callerPtr := add(swapUserDataPtr, memorySlot)
                mstore(callerPtr, caller())
            }
        }
    }

    function swapOnSwaapV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address vault,
        bytes calldata payload
    ) internal {

        (bool isBatchSwap) = abi.decode(payload, (bool));

        if(isBatchSwap) {

            (,
            uint256[] memory callerSlots,
            BalancerBatchData memory data
            ) = abi.decode(payload, (bool, uint256[], BalancerBatchData));

            uint256 totalSwaps = data.swaps.length;
            require(data.swaps.length == callerSlots.length);

            uint256 totalAmount;
            for (uint256 i = 0; i < totalSwaps; ++i) {
                IBalancerV2Vault.BatchSwapStep memory swap = data.swaps[i];
                substituteCallerOrigin(swap.userData, callerSlots[i]);
                totalAmount = totalAmount.add(swap.amount);
            }

            // This will only work for a direct swap on balancer
            if (totalAmount != fromAmount) {
                for (uint256 i = 0; i < totalSwaps; ++i) {
                    data.swaps[i].amount = data.swaps[i].amount.mul(fromAmount).div(totalAmount);
                }
            }

            if (address(fromToken) == Utils.ethAddress()) {
                IBalancerV2Vault(vault).batchSwap{ value: fromAmount }(
                    IBalancerV2Vault.SwapKind.GIVEN_IN,
                    data.swaps,
                    data.assets,
                    data.funds,
                    data.limits,
                    block.timestamp
                );
            } else {
                Utils.approve(vault, address(fromToken), fromAmount);
                IBalancerV2Vault(vault).batchSwap(
                    IBalancerV2Vault.SwapKind.GIVEN_IN,
                    data.swaps,
                    data.assets,
                    data.funds,
                    data.limits,
                    block.timestamp
                );
            }

        } else {

            (, uint256 callerSlot, BalancerSimpleData memory data) = abi.decode(payload, (bool, uint256, BalancerSimpleData));

            substituteCallerOrigin(data.singleSwap.userData, callerSlot);

            data.singleSwap.amount = fromAmount;

            if (address(fromToken) == Utils.ethAddress()) {
                IBalancerV2Vault(vault).swap{ value: fromAmount }(
                    data.singleSwap,
                    data.funds,
                    data.limit,
                    block.timestamp
                );
            } else {
                Utils.approve(vault, address(fromToken), fromAmount);
                IBalancerV2Vault(vault).swap(
                    data.singleSwap,
                    data.funds,
                    data.limit,
                    block.timestamp
                );
            }
        }
    }

    function buyOnSwaapV2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address vault,
        bytes calldata payload
    ) internal {

        (bool isBatchSwap) = abi.decode(payload, (bool));

        if(isBatchSwap) {

            (,
            uint256[] memory callerSlots,
            BalancerBatchData memory data
            ) = abi.decode(payload, (bool, uint256[], BalancerBatchData));

            uint256 totalSwaps = data.swaps.length;
            require(data.swaps.length == callerSlots.length);

            uint256 totalAmount;
            for (uint256 i = 0; i < totalSwaps; ++i) {
                IBalancerV2Vault.BatchSwapStep memory swap = data.swaps[i];
                substituteCallerOrigin(swap.userData, callerSlots[i]);
                totalAmount = totalAmount.add(swap.amount);
            }

            // This will only work for a direct swap on balancer
            if (totalAmount != toAmount) {
                for (uint256 i = 0; i < totalSwaps; ++i) {
                    data.swaps[i].amount = data.swaps[i].amount.mul(toAmount).div(totalAmount);
                }
            }

            if (address(fromToken) == Utils.ethAddress()) {
                IBalancerV2Vault(vault).batchSwap{ value: fromAmount }(
                    IBalancerV2Vault.SwapKind.GIVEN_OUT,
                    data.swaps,
                    data.assets,
                    data.funds,
                    data.limits,
                    block.timestamp
                );
            } else {
                Utils.approve(vault, address(fromToken), fromAmount);
                IBalancerV2Vault(vault).batchSwap(
                    IBalancerV2Vault.SwapKind.GIVEN_OUT,
                    data.swaps,
                    data.assets,
                    data.funds,
                    data.limits,
                    block.timestamp
                );
            }

        } else {

            (, uint256 callerSlot, BalancerSimpleData memory data) = abi.decode(payload, (bool, uint256, BalancerSimpleData));

            substituteCallerOrigin(data.singleSwap.userData, callerSlot);

            data.singleSwap.amount = toAmount;
            data.limit = fromAmount;

            if (address(fromToken) == Utils.ethAddress()) {
                IBalancerV2Vault(vault).swap{ value: fromAmount }(
                    data.singleSwap,
                    data.funds,
                    data.limit,
                    block.timestamp
                );
            } else {
                Utils.approve(vault, address(fromToken), fromAmount);
                IBalancerV2Vault(vault).swap(
                    data.singleSwap,
                    data.funds,
                    data.limit,
                    block.timestamp
                );
            }
        }
    }
}

/*solhint-disable avoid-low-level-calls */
// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../ITokenTransferProxy.sol";

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IERC20PermitLegacy {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library Utils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 private constant MAX_UINT = type(uint256).max;

    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct BuyData {
        address adapter;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Route[] route;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee; //NOT USED
        Route[] route;
    }

    struct Route {
        uint256 index; //Adapter at which index needs to be used
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee; //NOT USED - Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee; //NOT USED - Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }

    function ethAddress() internal pure returns (address) {
        return ETH_ADDRESS;
    }

    function maxUint() internal pure returns (uint256) {
        return MAX_UINT;
    }

    function approve(
        address addressToApprove,
        address token,
        uint256 amount
    ) internal {
        if (token != ETH_ADDRESS) {
            IERC20 _token = IERC20(token);

            uint256 allowance = _token.allowance(address(this), addressToApprove);

            if (allowance < amount) {
                _token.safeApprove(addressToApprove, 0);
                _token.safeIncreaseAllowance(addressToApprove, MAX_UINT);
            }
        }
    }

    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (token == ETH_ADDRESS) {
                (bool result, ) = destination.call{ value: amount, gas: 10000 }("");
                require(result, "Failed to transfer Ether");
            } else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }
    }

    function tokenBalance(address token, address account) internal view returns (uint256) {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    function permit(address token, bytes memory permit) internal {
        if (permit.length == 32 * 7) {
            (bool success, ) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            require(success, "Permit failed");
        }

        if (permit.length == 32 * 8) {
            (bool success, ) = token.call(abi.encodePacked(IERC20PermitLegacy.permit.selector, permit));
            require(success, "Permit failed");
        }
    }

    function transferETH(address payable destination, uint256 amount) internal {
        if (amount > 0) {
            (bool result, ) = destination.call{ value: amount, gas: 10000 }("");
            require(result, "Transfer ETH failed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(c >= a, "SafeMath: addition overflow");
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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface ITokenTransferProxy {
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "./ITokenTransferProxy.sol";

contract AugustusStorage {
    struct FeeStructure {
        uint256 partnerShare;
        bool noPositiveSlippage;
        bool positiveSlippageToUser;
        uint16 feePercent;
        string partnerId;
        bytes data;
    }

    ITokenTransferProxy internal tokenTransferProxy;
    address payable internal feeWallet;

    mapping(address => FeeStructure) internal registeredPartners;

    mapping(bytes4 => address) internal selectorVsRouter;
    mapping(bytes32 => bool) internal adapterInitialized;
    mapping(bytes32 => bytes) internal adapterVsData;

    mapping(bytes32 => bytes) internal routerData;
    mapping(bytes32 => bool) internal routerInitialized;

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

interface IAugustusRFQ {
    struct Order {
        uint256 nonceAndMeta; // first 160 bits is user address and then nonce
        uint128 expiry;
        address makerAsset;
        address takerAsset;
        address maker;
        address taker; // zero address on orders executable by anyone
        uint256 makerAmount;
        uint256 takerAmount;
    }

    // makerAsset and takerAsset are Packed structures
    // 0 - 159 bits are address
    // 160 - 161 bits are tokenType (0 ERC20, 1 ERC1155, 2 ERC721)
    struct OrderNFT {
        uint256 nonceAndMeta; // first 160 bits is user address and then nonce
        uint128 expiry;
        uint256 makerAsset;
        uint256 makerAssetId; // simply ignored in case of ERC20s
        uint256 takerAsset;
        uint256 takerAssetId; // simply ignored in case of ERC20s
        address maker;
        address taker; // zero address on orders executable by anyone
        uint256 makerAmount;
        uint256 takerAmount;
    }

    struct OrderInfo {
        Order order;
        bytes signature;
        uint256 takerTokenFillAmount;
        bytes permitTakerAsset;
        bytes permitMakerAsset;
    }

    struct OrderNFTInfo {
        OrderNFT order;
        bytes signature;
        uint256 takerTokenFillAmount;
        bytes permitTakerAsset;
        bytes permitMakerAsset;
    }

    /**
     @dev Allows taker to fill complete RFQ order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
    */
    function fillOrder(Order calldata order, bytes calldata signature) external;

    /**
     @dev Allows taker to fill Limit order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
    */
    function fillOrderNFT(OrderNFT calldata order, bytes calldata signature) external;

    /**
     @dev Same as fillOrder but allows sender to specify the target
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param target Address of the receiver
    */
    function fillOrderWithTarget(
        Order calldata order,
        bytes calldata signature,
        address target
    ) external;

    /**
     @dev Same as fillOrderNFT but allows sender to specify the target
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param target Address of the receiver
    */
    function fillOrderWithTargetNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        address target
    ) external;

    /**
     @dev Allows taker to partially fill an order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
    */
    function partialFillOrder(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Allows taker to partially fill an NFT order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
    */
    function partialFillOrderNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrder` but it allows to specify the destination address
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
    */
    function partialFillOrderWithTarget(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrderWithTarget` but it allows to pass permit
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
     @param permitTakerAsset Permit calldata for taker
     @param permitMakerAsset Permit calldata for maker
    */
    function partialFillOrderWithTargetPermit(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target,
        bytes calldata permitTakerAsset,
        bytes calldata permitMakerAsset
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrderNFT` but it allows to specify the destination address
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
    */
    function partialFillOrderWithTargetNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrderWithTargetNFT` but it allows to pass token permits
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
     @param permitTakerAsset Permit calldata for taker
     @param permitMakerAsset Permit calldata for maker
    */
    function partialFillOrderWithTargetPermitNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target,
        bytes calldata permitTakerAsset,
        bytes calldata permitMakerAsset
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Partial fill multiple orders
     @param orderInfos OrderInfo to fill
     @param target Address of receiver
    */
    function batchFillOrderWithTarget(OrderInfo[] calldata orderInfos, address target) external;

    /**
     @dev batch fills orders until the takerFillAmount is swapped
     @dev skip the order if it fails
     @param orderInfos OrderInfo to fill
     @param takerFillAmount total taker amount to fill
     @param target Address of receiver
    */
    function tryBatchFillOrderTakerAmount(
        OrderInfo[] calldata orderInfos,
        uint256 takerFillAmount,
        address target
    ) external;

    /**
     @dev batch fills orders until the makerFillAmount is swapped
     @dev skip the order if it fails
     @param orderInfos OrderInfo to fill
     @param makerFillAmount total maker amount to fill
     @param target Address of receiver
    */
    function tryBatchFillOrderMakerAmount(
        OrderInfo[] calldata orderInfos,
        uint256 makerFillAmount,
        address target
    ) external;

    /**
     @dev Partial fill multiple NFT orders
     @param orderInfos Info about each order to fill
     @param target Address of receiver
    */
    function batchFillOrderWithTargetNFT(OrderNFTInfo[] calldata orderInfos, address target) external;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

contract WethProvider {
    /*solhint-disable var-name-mixedcase*/
    address public immutable WETH;

    /*solhint-enable var-name-mixedcase*/

    constructor(address weth) public {
        WETH = weth;
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IWETH is IERC20 {
    function deposit() external payable virtual;

    function withdraw(uint256 amount) external virtual;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IDystPair {
    function getAmountOut(uint256, address) external view returns (uint256);

    function token0() external returns (address);

    function token1() external returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function stable() external returns (bool);
}

pragma solidity 0.7.5;
pragma abicoder v2;

/**
 * @title Contains the useful methods to a trader
 */
interface IPoolSwapSwaapV1 {
    /**
     * @notice Swap two tokens given the exact amount of token in
     * @param tokenIn The address of the input token
     * @param tokenAmountIn The exact amount of tokenIn to be swapped
     * @param tokenOut The address of the received token
     * @param minAmountOut The minimum accepted amount of tokenOut to be received
     * @param maxPrice The maximum spot price accepted before the swap
     * @return tokenAmountOut The token amount out received
     * @return spotPriceAfter The spot price of tokenOut in terms of tokenIn after the swap
     */
    function swapExactAmountInMMM(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    /**
     * @notice Swap two tokens given the exact amount of token out
     * @param tokenIn The address of the input token
     * @param maxAmountIn The maximum amount of tokenIn that can be swapped
     * @param tokenOut The address of the received token
     * @param tokenAmountOut The exact amount of tokenOut to be received
     * @param maxPrice The maximum spot price accepted before the swap
     * @return tokenAmountIn The amount of tokenIn added to the pool
     * @return spotPriceAfter The spot price of token out in terms of token in after the swap
     */
    function swapExactAmountOutMMM(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../Utils.sol";

interface IBalancerV2Vault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);
}