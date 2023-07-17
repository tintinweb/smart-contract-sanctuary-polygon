//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusAltairX.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

/*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  
    .         🛰️    .            .               .      🛰️     .           .                .           .
           █████████           ---======*.                                                .           ⠀
          ███░░░░░███                                               📡                🌔      🛰️                   . 
         ███     ░░░  █████ ████  ███████ ████████   █████ ████  █████        ⠀
        ░███         ░░███ ░███  ███░░███░░███░░███ ░░███ ░███  ███░░      .     .⠀           .          
        ░███          ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███ ░░█████       ⠀
        ░░███     ███ ░███ ░███ ░███ ░███ ░███ ░███  ░███ ░███  ░░░░███              .             .⠀🛰️
         ░░█████████  ░░███████ ░░███████ ████ █████ ░░████████ ██████     .----===*  ⠀
          ░░░░░░░░░    ░░░░░███  ░░░░░███░░░░ ░░░░░   ░░░░░░░░ ░░░░░░            .                            .⠀
                       ███ ░███  ███ ░███                .                 .                 .  ⠀
     🛰️  .             ░░██████  ░░██████                 🛰️                             .                 .           
                      ░░░░░░    ░░░░░░      -------=========*             🛰️         .                     ⠀
           .                            .🛰️       .          .            .                         🛰️ .             .⠀
    
        CYGNUS ALTAIR EXTENSION - `Hypervisor`                                                           
    ═══════════════════════════════════════════════════════════════════════════════════════════════════════════  */
pragma solidity >=0.8.17;

// Dependencies
import {ICygnusAltairX} from "./interfaces/ICygnusAltairX.sol";
import {ICygnusAltairCall} from "./interfaces/ICygnusAltairCall.sol";

// Libraries
import {CygnusDexLib} from "./libraries/CygnusDexLib.sol";
import {SafeTransferLib} from "./libraries/SafeTransferLib.sol";
import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

// Interfaces
import {IERC20} from "./interfaces/core/IERC20.sol";
import {IHangar18} from "./interfaces/core/IHangar18.sol";
import {ICygnusAltair} from "./interfaces/ICygnusAltair.sol";
import {IWrappedNative} from "./interfaces/IWrappedNative.sol";
import {ICygnusBorrow} from "./interfaces/core/ICygnusBorrow.sol";
import {ICygnusCollateral} from "./interfaces/core/ICygnusCollateral.sol";
import {IAllowanceTransfer} from "./interfaces/core/IAllowanceTransfer.sol";

// Aggregators
import {IAugustusSwapper} from "./interfaces/aggregators/IAugustusSwapper.sol";
import {IAggregationRouterV5, IAggregationExecutor} from "./interfaces/aggregators/IAggregationRouterV5.sol";

// ---- Extension ---- //
import {IHypervisor, IGammaProxy} from "./interfaces-extension/IHypervisor.sol";
import {ICygnusNebulaRegistry} from "./interfaces-extension/ICygnusNebulaRegistry.sol";

/**
 *  @title  CygnusAltairX Extension for Hypervisor pools
 *  @author CygnusDAO
 *  @notice Router that is used to leverage, deleverage and flash liquidate Hypervisor positions. External
 *          functions can only be called through delegatecalls or else the tx reverts.
 */
contract CygnusAltairX is ICygnusAltairX, ICygnusAltairCall {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
          1. LIBRARIES
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @custom:library SafeTransferLib For safe transfers of Erc20 tokens
     */
    using SafeTransferLib for address;

    /**
     *  @custom:library FixedPointMathLib Arithmetic library with operations for fixed-point numbers
     */
    using FixedPointMathLib for uint256;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
          2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Empty bytes to pass to contracts if needed
     */
    bytes internal constant LOCAL_BYTES = new bytes(0);

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    address private immutable _contractAddress;

    /**
     *  @inheritdoc ICygnusAltairX
     */
    string public override name;

    /**
     *  @inheritdoc ICygnusAltairX
     */
    address public constant override PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;

    /**
     *  @inheritdoc ICygnusAltairX
     */
    address public constant override PARASWAP_AUGUSTUS_SWAPPER_V5 = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    /**
     *  @inheritdoc ICygnusAltairX
     */
    address public constant override ONE_INCH_ROUTER_V5 = 0x1111111254EEB25477B68fb85Ed929f73A960582;

    /**
     *  @inheritdoc ICygnusAltairX
     */
    address public constant override OxPROJECT_EXCHANGE_PROXY = 0xDEF1ABE32c034e558Cdd535791643C58a13aCC10;

    /**
     *  @inheritdoc ICygnusAltairX
     */
    IHangar18 public immutable override hangar18;

    /**
     *  @inheritdoc ICygnusAltairX
     */
    address public immutable override usd;

    /**
     *  @inheritdoc ICygnusAltairX
     */
    IWrappedNative public immutable override nativeToken;

    /**
     *  @notice Empty permit for permit2 router
     */
    IAllowanceTransfer.PermitSingle public emptyPermit;

    /*  ────────────────────── Strategy  ──────────────────────  */

    /**
     *  @notice Oracle to get the token weights
     */
    ICygnusNebulaRegistry public immutable nebula;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
          3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Constructs the periphery contract. Factory must be deployed on the chain first to get the addresses
     *          of deployers and the wrapped native token (WETH, WFTM, etc.)
     *  @param _hangar18 The address of the Cygnus Factory contract on this chain
     */
    constructor(IHangar18 _hangar18, string memory _name, ICygnusNebulaRegistry _nebula) {
        // Name
        name = string(abi.encodePacked("Cygnus: Altair Router Extension - ", _name));

        // Factory
        hangar18 = _hangar18;

        // Assign the native token set at the factory
        nativeToken = IWrappedNative(_hangar18.nativeToken());

        // Assign the USD address set at the factoryn
        usd = _hangar18.usd();

        // Gamma LP oracle
        nebula = _nebula;

        // Store the contract address to restrict certain functions to delegate only
        _contractAddress = address(this);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
          4. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @notice Allows only delegate calls.
    modifier onlyDelegateCall() {
        _checkAddress();
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
          5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── Internal ───────────────────────────────────────────────  */

    /**
     *  @notice Checks address(this) to see if the call is being delegated. Reverts if it returns this contract's
     *          stored address.
     */
    function _checkAddress() private view {
        /// @custom:error OnlyDelegateCall Avoid if the call is not a delegate call
        if (address(this) == _contractAddress) revert CygnusAltair__OnlyDelegateCall();
    }

    /**
     *  @notice Checks the `token` balance of this contract
     *  @param token The token to view balance of
     *  @return amount This contract's `token` balance
     */
    function _checkBalance(address token) internal view returns (uint256) {
        // Our balance of `token` (uses solady lib)
        return token.balanceOf(address(this));
    }

    /*  ─────────────────────────────────────────────── Public ────────────────────────────────────────────────  */

    /**
     *  @notice Get the token weights - Not to be called on-chain
     */
    function getTokenWeights(
        address lpTokenPair
    ) external view returns (address token0, address token1, uint256 token0Weight, uint256 token1Weight) {
        // Get prices
        uint256[] memory prices = nebula.getAssetPricesUsd(lpTokenPair);

        // Get reserves from the LP
        (uint256 reserves0, uint256 reserves1) = IHypervisor(lpTokenPair).getTotalAmounts();

        // Tokens
        token0 = IHypervisor(lpTokenPair).token0();
        token1 = IHypervisor(lpTokenPair).token1();

        // TVL of token0
        uint256 value0 = ((prices[0] * 10 ** (18 - 6)) * reserves0) / (10 ** IERC20(token0).decimals());
        uint256 value1 = ((prices[1] * 10 ** (18 - 6)) * reserves1) / (10 ** IERC20(token1).decimals());

        // TVL
        uint256 totalUsd = value0 + value1;

        // Return weights on each side
        token0Weight = value0.divWad(totalUsd);
        token1Weight = 1e18 - token0Weight;
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @inheritdoc ICygnusAltairX
     */
    function getAssetsForShares(
        address underlying,
        uint256 shares,
        uint256 slippage
    ) external view override returns (address[] memory tokens, uint256[] memory amounts) {
        // Get total supply of the underlying pool
        uint256 totalSupply = IHypervisor(underlying).totalSupply();

        // Get reserves from the LP
        (uint256 reserves0, uint256 reserves1) = IHypervisor(underlying).getTotalAmounts();

        // Initialize the arrays
        tokens = new address[](2);

        // Empty amounts
        amounts = new uint256[](2);

        // Token 0 from the underlying
        tokens[0] = IHypervisor(underlying).token0();

        // Token1 from the underlying
        tokens[1] = IHypervisor(underlying).token1();

        // Same calculation as other vault tokens, asset = shares * balance / supply

        // Amount out token0 from the LP
        amounts[0] = shares.fullMulDiv(reserves0, totalSupply) - slippage;

        // Amount of token1 from the LP
        amounts[1] = shares.fullMulDiv(reserves1, totalSupply) - slippage;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
          6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ───────────────────────────────────────────── Internal ────────────────────────────────────────────────  */

    // Approvals

    /**
     *  @notice Grants allowance from this contract to a dex' router (or just a contract instead of `router`)
     *  @param token The address of the token we are approving
     *  @param router The address of the dex router we are approving (or just a contract)
     *  @param amount The amount to approve
     */
    function _approveToken(address token, address router, uint256 amount) internal {
        // If allowance is already higher than `amount` return
        if (IERC20(token).allowance(address(this), router) >= amount) return;

        // Approve token
        token.safeApprove(router, type(uint256).max);
    }

    /**
     *  @notice Approves permit2 in `token` - This is used to deposit leveraged liquidity back into the CygnusCollateral
     *  @param token The address of the token we are approving the permit2 router in
     *  @param spender The address of the contract we are allowing to move our `token` (CygnusCollateral)
     *  @param amount The amount we are allowing
     */
    function _approvePermit2(address token, address spender, uint256 amount) internal {
        // Get allowance
        (uint160 allowed, , ) = IAllowanceTransfer(PERMIT2).allowance(address(this), token, spender);

        // Return without approving
        if (allowed >= amount) return;

        // We approve to the max uint160 allowed and max allowed deadline
        IAllowanceTransfer(PERMIT2).approve(token, spender, type(uint160).max, type(uint48).max);
    }

    // AGGREGATORS

    /**
     *  @notice Creates the swap with Paraswap's Augustus Swapper. We don't update the amount, instead we clean dust at the end.
     *          This is because the data is of complex type (Path[] path). We pass the token being swapped and the amount being
     *          swapped to approve the transfer proxy (which is set on augustus wrapped via `getTokenTransferProxy`).
     *  @param swapdata The data from Paraswap's `transaction` query
     *  @param srcToken The token being swapped
     *  @param srcAmount The amount of `srcToken` being swapped
     *  @return amountOut The amount received of destination token
     */
    function _swapTokensParaswap(bytes memory swapdata, address srcToken, uint256 srcAmount) internal returns (uint256 amountOut) {
        // Paraswap's token proxy to approve in srcToken
        address paraswapTransferProxy = IAugustusSwapper(PARASWAP_AUGUSTUS_SWAPPER_V5).getTokenTransferProxy();

        // Approve Paraswap's transfer proxy in `srcToken` if necessary
        _approveToken(srcToken, paraswapTransferProxy, srcAmount);

        // Call the augustus wrapper with the data passed, triggering the fallback function for multi/mega swaps
        (bool success, bytes memory resultData) = PARASWAP_AUGUSTUS_SWAPPER_V5.call{value: msg.value}(swapdata);

        /// @custom:error ParaswapTransactionFailed
        if (!success) revert CygnusAltair__ParaswapTransactionFailed();

        // Return amount received - This is off by some very small amount from the actual contract balance.
        // We shouldn't use it directly. Instead, query contract balance of token received
        assembly {
            amountOut := mload(add(resultData, 32))
        }
    }

    // Swap tokens via 1inch legacy (aka `swap` method)

    /**
     *  @notice Creates the swap with 1Inch's AggregatorV5. We pass an extra param `updatedAmount` to eliminate
     *          any slippage from the byte data passed. When calculating the optimal deposit for single sided
     *          liquidity deposit, our calculation can be off for a few mini tokens which don't affect the
     *          data of the aggregation executor, so we pass the tx data as is but update the srcToken amount
     *  @param swapdata The data from 1inch `swap` query
     *  @param srcAmount The balanceOf this contract`s srcToken
     *  @return amountOut The amount received of destination token
     */
    function _swapTokensOneInchV1(bytes memory swapdata, address srcToken, uint256 srcAmount) internal returns (uint256 amountOut) {
        // Get aggregation executor, swap params and the encoded calls for the executor from 1inch API call
        (address caller, IAggregationRouterV5.SwapDescription memory desc, bytes memory permit, bytes memory data) = abi.decode(
            swapdata,
            (address, IAggregationRouterV5.SwapDescription, bytes, bytes)
        );

        // Update swap amount to current balance of src token (if needed)
        if (desc.amount != srcAmount) desc.amount = srcAmount;

        // Approve 1Inch Router in `srcToken` if necessary
        _approveToken(srcToken, address(ONE_INCH_ROUTER_V5), srcAmount);

        // Swap `srcToken` to `dstToken` - Aggregator does the necessary minAmount check & we do checks at the end
        // of the leverage/deleverage functions anyways
        (amountOut, ) = IAggregationRouterV5(ONE_INCH_ROUTER_V5).swap(IAggregationExecutor(caller), desc, permit, data);
    }

    // Swap tokens via 1inch optimized routers

    /**
     *  @notice Creates the swap with 1Inch's AggregatorV5 using the router's latest paths (unoswap, uniswapv3, etc.)
     *  @param swapdata The data from 1inch `swap` query
     *  @param srcAmount The balanceOf this contract`s srcToken
     *  @return amountOut The amount received of destination token
     */
    function _swapTokensOneInchV2(bytes memory swapdata, address srcToken, uint256 srcAmount) internal returns (uint256 amountOut) {
        // Approve 1Inch Router in `srcToken` if necessary
        _approveToken(srcToken, address(ONE_INCH_ROUTER_V5), srcAmount);

        // Call the augustus wrapper with the data passed, triggering the fallback function for multi/mega swaps
        (bool success, bytes memory resultData) = ONE_INCH_ROUTER_V5.call{value: msg.value}(swapdata);

        /// @custom:error OneInchTransactionFailed
        if (!success) revert CygnusAltair__OneInchTransactionFailed();

        // Return amount received
        assembly {
            amountOut := mload(add(resultData, 32))
        }
    }

    // Swap tokens via 0xProject's swap API

    /**
     *  @notice Creates the swap with OxProject's swap API
     *  @param swapdata The data from 0x's swap api `quote` query
     *  @param srcAmount The balanceOf this contract`s srcToken
     *  @return amountOut The amount received of destination token
     */
    function _swapTokens0xProject(bytes memory swapdata, address srcToken, uint256 srcAmount) internal returns (uint256 amountOut) {
        // Approve 0x Exchange Proxy Router in `srcToken` if necessary
        _approveToken(srcToken, address(OxPROJECT_EXCHANGE_PROXY), srcAmount);

        // Call the augustus wrapper with the data passed, triggering the fallback function for multi/mega swaps
        (bool success, bytes memory resultData) = OxPROJECT_EXCHANGE_PROXY.call{value: msg.value}(swapdata);

        /// @custom:error 0xProjectTransactionFailed
        if (!success) revert CygnusAltair__0xProjectTransactionFailed();

        // Return amount received
        assembly {
            amountOut := mload(add(resultData, 32))
        }
    }

    /**
     *  @dev Internal function to swap tokens using the specified aggregator.
     *  @param dexAggregator The aggregator to use for the token swap
     *  @param swapdata The encoded swap data for the aggregator.
     *  @param srcToken The source token to swap
     *  @param srcAmount The amount of source token to swap
     *  @return amountOut The amount of swapped tokens received
     */
    function _swapTokensAggregator(
        ICygnusAltair.DexAggregator dexAggregator,
        bytes memory swapdata,
        address srcToken,
        uint256 srcAmount
    ) internal returns (uint256 amountOut) {
        // Check which dex aggregator to use
        // Case 1: PARASWAP
        if (dexAggregator == ICygnusAltair.DexAggregator.PARASWAP) {
            amountOut = _swapTokensParaswap(swapdata, srcToken, srcAmount);
        }
        // Case 2: ONE INCH LEGACY
        else if (dexAggregator == ICygnusAltair.DexAggregator.ONE_INCH_LEGACY) {
            amountOut = _swapTokensOneInchV1(swapdata, srcToken, srcAmount);
        }
        // Case 3: ONE INCH V2
        else if (dexAggregator == ICygnusAltair.DexAggregator.ONE_INCH_V2) {
            amountOut = _swapTokensOneInchV2(swapdata, srcToken, srcAmount);
        }
        // Case 4: 0xPROJECT
        else if (dexAggregator == ICygnusAltair.DexAggregator.OxPROJECT) {
            amountOut = _swapTokens0xProject(swapdata, srcToken, srcAmount);
        }
    }

    /**
     *  @param borrowable Address of the Cygnus borrow contract
     *  @param token Address of the token we are repaying (USD)
     *  @param borrower Address of the borrower who is repaying the loan
     *  @param amountMax The max available amount
     */
    function _repayAndRefund(address collateral, address borrowable, address token, address borrower, uint256 amountMax) internal {
        // Repay
        uint256 amount = _maxRepayAmount(collateral, borrowable, amountMax, borrower);

        // Safe transfer USD to borrowable
        token.safeTransfer(borrowable, amount);

        // Cygnus Borrow with address(0) to update borrow balances
        ICygnusBorrow(borrowable).borrow(collateral, borrower, address(0), 0, LOCAL_BYTES);

        // Refund excess
        if (amountMax > amount) {
            uint256 refundAmount = amountMax - amount;
            // Check if token is native
            if (token == address(nativeToken)) {
                // Withdraw native
                nativeToken.withdraw(refundAmount);

                // Transfer native
                borrower.safeTransferETH(refundAmount);
            } else {
                // Transfer Token
                token.safeTransfer(borrower, refundAmount);
            }
        }
    }

    /**
     *  @notice Safe internal function to repay borrowed amount
     *  @param borrowable The address of the Cygnus borrow arm where the borrowed amount was taken from
     *  @param amountMax The max amount that can be repaid
     *  @param borrower The address of the account that is repaying the borrowed amount
     */
    function _maxRepayAmount(
        address collateral,
        address borrowable,
        uint256 amountMax,
        address borrower
    ) internal returns (uint256 amount) {
        // Accrue interest first to not leave debt after full repay
        ICygnusBorrow(borrowable).accrueInterest();

        // Get borrow balance of borrower
        (, uint256 borrowedAmount) = ICygnusBorrow(borrowable).getBorrowBalance(collateral, borrower);

        // Avoid repaying more than borrowedAmount
        amount = amountMax < borrowedAmount ? amountMax : borrowedAmount;
    }

    /************************** CUSTOM ****************************/

    /**
     *  @notice This function gets called after calling `borrow` on Borrow contract and having `amountUsd` of USD
     *  @notice Maximum 2 swaps
     *  @param token0 The address of token0 from the LP Token
     *  @param token1 The address of token1 from the LP Token
     *  @param amountUsd The amount of USD to convert to LP
     *  @param swapdata Bytes array consisting of 1inch API swap data
     *  @return liquidity The amount of LP minted
     */
    function _convertUsdToLiquidity(
        ICygnusAltair.DexAggregator dexAggregator,
        address token0,
        address token1,
        uint256 amountUsd,
        bytes[] memory swapdata,
        address lpTokenPair
    ) private returns (uint256 liquidity) {
        // Swap USD to tokenA using dex aggregator
        if (token0 != usd) _swapTokensAggregator(dexAggregator, swapdata[0], usd, amountUsd);

        // Swap USD to tokenA using dex aggregator
        if (token1 != usd) _swapTokensAggregator(dexAggregator, swapdata[1], usd, amountUsd);

        // Check balance of token0
        uint256 deposit0 = _checkBalance(token0);

        // Balance of token1
        uint256 deposit1 = _checkBalance(token1);

        // Approve token0 in hypervisor
        _approveToken(token0, lpTokenPair, deposit0);

        // Approve token1 in hypervisor
        _approveToken(token1, lpTokenPair, deposit1);

        // Get the whitelsited address - the only one allowed to deposit in hypervisor
        address gammaUniProxy = IHypervisor(lpTokenPair).whitelistedAddress();

        // Mint LP
        liquidity = IGammaProxy(gammaUniProxy).deposit(deposit0, deposit1, address(this), lpTokenPair, [uint256(0), 0, 0, 0]);
    }

    /**
     *  @notice Converts an amount of LP Token to USD. It is called after calling `burn` on a uniswapV2 pair, which
     *          receives amountTokenA of token0 and amountTokenB of token1.
     *  @notice Maximum 2 swaps
     *  @param amountTokenA The amount of token A to convert to USD
     *  @param amountTokenB The amount of token B to convert to USD
     *  @param token0 The address of token0 from the LP Token pair
     *  @param token1 The addre.s of token1 from the LP Token pair
     *  @param swapdata Bytes array consisting of 1inch API swap data
     */
    function _convertLiquidityToUsd(
        ICygnusAltair.DexAggregator dexAggregator,
        uint256 amountTokenA,
        uint256 amountTokenB,
        address token0,
        address token1,
        bytes[] memory swapdata
    ) private returns (uint256) {
        // ─────────────────────── 1. Check if token0 or token1 is already USD
        uint256 amountA;
        uint256 amountB;

        // If token0 or token1 is USD then swap opposite
        if (token0 == usd || token1 == usd) {
            // Convert the other token to USD and return
            (amountA, amountB) = token0 == usd
                ? (amountTokenA, _swapTokensAggregator(dexAggregator, swapdata[1], token1, amountTokenB))
                : (_swapTokensAggregator(dexAggregator, swapdata[0], token0, amountTokenA), amountTokenB);

            // Explicit return
            return amountA + amountB;
        }

        // ─────────────────── 2. Not USD, swap both to USD
        // Swap token0 to USD
        amountA = _swapTokensAggregator(dexAggregator, swapdata[0], token0, amountTokenA);

        // Swap token1 to USD
        amountB = _swapTokensAggregator(dexAggregator, swapdata[1], token1, amountTokenB);

        // USD balance
        return amountA + amountB;
    }

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    //  LIQUIDATE ─────────────────────────────

    /**
     *  @notice Liquidates borrower internally and converts LP Tokens to receive back USD
     *  @param lpTokenPair The address of the LP Token
     *  @param collateral The address of the Cygnus Collateral
     *  @param borrowable The address of the borrowable contract
     *  @param seizeTokens The amount of CygLP seized
     *  @param swapdata The 1inch calldata to swap LP back to USD
     *  @return usdAmount The amount of USD received
     */
    function _flashLiquidate(
        address lpTokenPair,
        address collateral,
        address borrowable,
        address recipient,
        uint256 seizeTokens,
        uint256 repayAmount,
        ICygnusAltair.DexAggregator dexAggregator,
        bytes[] memory swapdata
    ) internal returns (uint256 usdAmount) {
        // Calculate LP amount to redeem
        uint256 redeemAmount = seizeTokens.mulWad(ICygnusCollateral(collateral).exchangeRate());

        // Flash redeem the LP back to the contract
        ICygnusCollateral(collateral).flashRedeemAltair(address(this), redeemAmount, LOCAL_BYTES);

        // Burn LP Token and return amountA and amountB
        (uint256 amountAMax, uint256 amountBMax) = IHypervisor(lpTokenPair).withdraw(
            redeemAmount,
            address(this),
            address(this),
            [uint256(0), 0, 0, 0]
        );

        // Token0 and token1 from the LP
        address token0 = IHypervisor(lpTokenPair).token0();
        address token1 = IHypervisor(lpTokenPair).token1();

        // Convert amountA and amountB to USD
        _convertLiquidityToUsd(dexAggregator, amountAMax, amountBMax, token0, token1, swapdata);

        // Manually get the balance, this is because in some cases the amount returned by aggregators is not 100% accurate
        usdAmount = _checkBalance(usd);

        /// @custom:error InsufficientLiquidateUsd Avoid if received is less than liquidated
        if (usdAmount < repayAmount) revert CygnusAltair__InsufficientLiquidateUsd();

        // Transfer USD to recipient
        usd.safeTransfer(recipient, usdAmount - repayAmount);

        // Transfer the repay amount of USD to borrowable
        usd.safeTransfer(borrowable, repayAmount);

        // Clean dust from selling tokens to USDC
        _cleanDust(token0, token1, recipient);
    }

    /**
     *  @inheritdoc ICygnusAltairCall
     *  @custom:security only-delegate
     */
    function altairLiquidate_f2x(
        address sender,
        uint256 cygLPAmount,
        uint256 repayAmount,
        bytes calldata data
    ) external virtual override(ICygnusAltairCall) onlyDelegateCall {
        // Decode data passed from borrow contract
        ICygnusAltair.AltairLiquidateCalldata memory cygnusShuttle = abi.decode(data, (ICygnusAltair.AltairLiquidateCalldata));

        /// @custom:error MsgSenderNotRouter Avoid if the caller is not the router
        if (sender != address(this)) revert CygnusAltair__MsgSenderNotRouter();
        /// @custom:error MsgSenderNotBorrowable Avoid if the msg sender is not the borrow contract
        else if (msg.sender != cygnusShuttle.borrowable) revert CygnusAltair__MsgSenderNotBorrowable();

        // Convert CygLP to USD
        _flashLiquidate(
            cygnusShuttle.lpTokenPair,
            cygnusShuttle.collateral,
            cygnusShuttle.borrowable,
            cygnusShuttle.recipient,
            cygLPAmount, // Seized amount of CygLP
            repayAmount,
            cygnusShuttle.dexAggregator,
            cygnusShuttle.swapdata
        );
    }

    //  LEVERAGE ─────────────────────────────────────

    /**
     *  @notice Mints liquidity from the DEX and deposits in the collateral, minting CygLP to the recipient
     *  @param lpTokenPair The address of the LP Token
     *  @param recipient The address of the recipient
     *  @param collateral The address of the Cygnus Collateral contract
     *  @param borrowAmount The amount of USD borrowed to conver to LP
     *  @param lpAmountMin The minimum amount of LP allowed to receive
     *  @param swapdata Swap data for aggregator
     */
    function _mintLPAndDeposit(
        address lpTokenPair,
        address recipient,
        address collateral,
        uint256 borrowAmount,
        uint256 lpAmountMin,
        ICygnusAltair.DexAggregator dexAggregator,
        bytes[] memory swapdata
    ) private returns (uint256 liquidity) {
        // Get tokens from the LP
        address token0 = IHypervisor(lpTokenPair).token0();
        address token1 = IHypervisor(lpTokenPair).token1();

        // Converts the borrowed amount of USD to tokenA and tokenB to mint the LP Token
        liquidity = _convertUsdToLiquidity(dexAggregator, token0, token1, borrowAmount, swapdata, lpTokenPair);

        /// @custom:error InsufficientLPTokenAmount Avoid if LP Token amount received is less than min
        if (liquidity < lpAmountMin) revert CygnusAltair__InsufficientLPTokenAmount();

        // Check allowance and deposit the LP token in the collateral contract
        _approveToken(lpTokenPair, address(PERMIT2), liquidity);

        // Approve Permit
        _approvePermit2(lpTokenPair, collateral, liquidity);

        // Mint CygLP to the recipient
        ICygnusCollateral(collateral).deposit(liquidity, recipient, emptyPermit, LOCAL_BYTES);

        // Check for dust from after leverage
        _cleanDust(token0, token1, recipient);
    }

    /**
     *  @inheritdoc ICygnusAltairCall
     *  @custom:security only-delegate
     */
    function altairBorrow_O9E(
        address sender,
        uint256 borrowAmount,
        bytes calldata data
    ) external virtual override(ICygnusAltairCall) onlyDelegateCall returns (uint256 liquidity) {
        // Decode data passed from borrow contract
        ICygnusAltair.AltairLeverageCalldata memory cygnusShuttle = abi.decode(data, (ICygnusAltair.AltairLeverageCalldata));

        /// @custom:error MsgSenderNotRouter Avoid if the caller is not the router
        if (sender != address(this)) revert CygnusAltair__MsgSenderNotRouter();
        /// @custom:error MsgSenderNotBorrowable Avoid if the msg sender is not the borrow contract
        else if (msg.sender != cygnusShuttle.borrowable) revert CygnusAltair__MsgSenderNotBorrowable();

        // Mint LP and deposit in collateral
        liquidity = _mintLPAndDeposit(
            cygnusShuttle.lpTokenPair,
            cygnusShuttle.recipient,
            cygnusShuttle.collateral,
            borrowAmount,
            cygnusShuttle.lpAmountMin,
            cygnusShuttle.dexAggregator,
            cygnusShuttle.swapdata
        );
    }

    //  DELEVERAGE ───────────────────────────────────

    /**
     *  @notice Removes liquidity from the Dex by calling the pair's `burn` function, receiving tokenA and tokenB
     *  @notice Ideally the dex would already have the LP so we can just call burn (check `deleveragePrivate()`)
     *  @param lpTokenPair The address of the LP Token
     *  @param borrower The address of the recipient
     *  @param collateral The address of the Cygnus Collateral contract
     *  @param redeemTokens The amount of CygLP to redeem
     *  @param usdAmountMin The minimum amount of USD allowed to receive
     *  @param swapdata Swap data for aggregator
     */
    function _removeLPAndRepay(
        address lpTokenPair,
        address borrower,
        address collateral,
        uint256 redeemTokens,
        uint256 redeemAmount,
        uint256 usdAmountMin,
        ICygnusAltair.DexAggregator dexAggregator,
        bytes[] memory swapdata
    ) private returns (uint256 usdAmount) {
        // Burn LP Token and return amountA and amountB
        (uint256 amountAMax, uint256 amountBMax) = IHypervisor(lpTokenPair).withdraw(
            redeemAmount,
            address(this),
            address(this),
            [uint256(0), 0, 0, 0]
        );

        // Token0 from the LP
        address token0 = IHypervisor(lpTokenPair).token0();

        // Token1 from the LP
        address token1 = IHypervisor(lpTokenPair).token1();

        // Convert amountA and amountB to USD
        _convertLiquidityToUsd(dexAggregator, amountAMax, amountBMax, token0, token1, swapdata);

        // Manually get the balance, this is because in some cases the amount returned by aggregators is not 100% accurate
        usdAmount = _checkBalance(usd);

        /// @custom:error InsufficientRedeemAmount Avoid if USD received is less than min
        if (usdAmount < usdAmountMin) revert CygnusAltair__InsufficientUSDAmount();

        // Repay USD
        _repayAndRefund(collateral, ICygnusCollateral(collateral).borrowable(), usd, borrower, usdAmount);

        // repay flash redeem
        ICygnusCollateral(collateral).transferFrom(borrower, collateral, redeemTokens);

        // Check for dust from after deleverage
        _cleanDust(token0, token1, borrower);
    }

    /**
     *  @inheritdoc ICygnusAltairCall
     *  @custom:security only-delegate
     */
    function altairRedeem_u91A(
        address sender,
        uint256 redeemAmount,
        bytes calldata data
    ) external virtual override(ICygnusAltairCall) onlyDelegateCall returns (uint256 usdAmount) {
        // Decode deleverage shuttle data
        ICygnusAltair.AltairDeleverageCalldata memory redeemData = abi.decode(data, (ICygnusAltair.AltairDeleverageCalldata));

        /// @custom:error MsgSenderNotRouter Avoid if the caller is not the router
        if (sender != address(this)) revert CygnusAltair__MsgSenderNotRouter();
        /// @custom:error MsgSenderNotCollateral Avoid if the msg sender is not Cygnus collateral contract
        else if (msg.sender != redeemData.collateral) revert CygnusAltair__MsgSenderNotCollateral();

        // Burn LP and withdraw from collateral
        usdAmount = _removeLPAndRepay(
            redeemData.lpTokenPair,
            redeemData.recipient,
            redeemData.collateral,
            redeemData.redeemTokens,
            redeemAmount,
            redeemData.usdAmountMin,
            redeemData.dexAggregator,
            redeemData.swapdata
        );
    }

    ////// Clean Dust ////////

    /**
     *  @notice Send dust to user who leveraged USDC into LP, if any
     *  @param token0 The address of token0 from the LP
     *  @param token1 The address of token1 from the LP
     *  @param recipient The address of the user leveraging the position
     */
    function _cleanDust(address token0, address token1, address recipient) internal {
        // Check for dust of token0
        uint256 leftAmount0 = _checkBalance(token0);

        // Check for dust of token1
        uint256 leftAmount1 = _checkBalance(token1);

        // Send leftover token0 to user
        if (leftAmount0 > 0) token0.safeTransfer(recipient, leftAmount0);

        // Send leftover token1 to user
        if (leftAmount1 > 0) token1.safeTransfer(recipient, leftAmount1);
    }

    /**
     *  @notice Updates the name of the extension
     *  @custom:security only-admin
     */
    function setName(string memory _name) external {
        // Get latest admin
        address admin = hangar18.admin();

        /// @custom:error MsgSenderNotAdmin
        if (msg.sender != admin) revert("Only admin");

        // Update name
        name = _name;
    }
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusNebulaRegistry.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.17;

/**
 *  @title ICygnusNebulaRegistry Interface to interact with Cygnus' LP Oracle
 *  @author CygnusDAO
 */
interface ICygnusNebulaRegistry {

    /**
     *  @notice Get the price of each asset of the LP
     *  @param lpTokenPair The address of the LP Token pair
     *  @return prices Array of prices of each asset from the LP (can be 2 or more ie Balancer/Beethovenx)
     */
    function getAssetPricesUsd(address lpTokenPair) external view returns (uint256[] memory prices);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.17;

interface IHypervisor {
    function getTotalAmounts() external view returns (uint256 total0, uint256 total1);

    function getBasePosition() external view returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    function baseLower() external view returns (int24);

    function baseUpper() external view returns (int24);

    function limitLower() external view returns (int24);

    function limitUpper() external view returns (int24);

    function pool() external view returns (address);

    function totalSupply() external view returns (uint256);

    /// @param shares Number of liquidity tokens to redeem as pool assets
    /// @param to Address to which redeemed pool assets are sent
    /// @param from Address from which liquidity tokens are sent
    /// @param minAmounts min amount0,1 returned for shares of liq
    /// @return amount0 Amount of token0 redeemed by the submitted liquidity tokens
    /// @return amount1 Amount of token1 redeemed by the submitted liquidity tokens
    function withdraw(
        uint256 shares,
        address to,
        address from,
        uint256[4] memory minAmounts
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Deposit tokens
    /// @param deposit0 Amount of token0 transfered from sender to Hypervisor
    /// @param deposit1 Amount of token1 transfered from sender to Hypervisor
    /// @param to Address to which liquidity tokens are minted
    /// @param from Address from which asset tokens are transferred
    /// @param inMin min spend for directDeposit is true
    /// @return shares Quantity of liquidity tokens minted as a result of deposit
    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to,
        address from,
        uint256[4] memory inMin
    ) external returns (uint256 shares);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function whitelistedAddress() external view returns (address);
}

interface IGammaProxy {
    function deposit(uint256 deposit0, uint256 deposit1, address to, address pos, uint256[4] memory inMin) external returns (uint256 liquidity);

    function getDepositAmount(address, address, uint256) external returns (uint256, uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

import {IERC20} from "../core/IERC20.sol";

/**
 *  @title Interface for making arbitrary calls during swap
 */
interface IAggregationExecutor {
    /**
     *  @notice Executes calls for `msgSender`
     */
    function execute(address msgSender) external payable; // 0x4b64e492
}

/**
 * @title IAggregationRouterV4 OneInch's Aggregation Router
 */
interface IAggregationRouterV5 {
    /**
     *  @custom:member srcToken The address of the token we are swapping
     *  @custom:member dstToken The address of the token we are receiving
     *  @custom:member srcReceiver The address that is swapping the tokens
     *  @custom:member dstReceiver The address that is receiving the tokens
     *  @custom:member amount Amount of `srcToken` we are swapping
     *  @custom:member minReturnAmount The min return amount of `srcToken`
     *  @custom:member flags Flags for the swap
     */
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    /**
     * @notice Performs a swap, delegating all calls encoded in `data` to `caller`. See tests for usage examples
     * @param caller Aggregation executor that executes calls described in `data`
     * @param desc Swap description
     * @param data Encoded calls that `caller` should execute in between of swaps
     * @param permit Permit data for the swap, we pass LOCAL_BYTES
     * @return returnAmount Resulting token amount
     * @return spentAmount Spent amount from the swap
     */
    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

interface IAugustusSwapper {
    // MultiSwap calldata
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee; //NOT USED - Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }

    struct Adapter {
        address payable adapter;
    }

    function getTokenTransferProxy() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce);

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration);

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration, uint48 nonce);

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address, address, address) external view returns (uint160, uint48, uint48);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(address token, address spender, uint48 newNonce) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusBorrow.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

import {IERC20Permit} from "./IERC20Permit.sol";

interface ICygnusBorrow is IERC20Permit { 
    /**
     *  @notice This low level function should only be called from `CygnusAltair` contract only
     *
     *  @param borrower The address of the Borrow contract.
     *  @param receiver The address of the receiver of the borrow amount.
     *  @param borrowAmount The amount of the underlying asset to borrow.
     *  @param data Calltype data passed to Router contract.
     *
     *  @custom:security non-reentrant
     */
    function borrow(address collateral, address borrower, address receiver, uint256 borrowAmount, bytes calldata data) external returns (uint256);

    /**
     *  @notice This low level function should only be called from `CygnusAltair` contract only
     *
     *  @param borrower The address of the borrower being liquidated
     *  @param receiver The address of the receiver of the collateral
     *  @param repayAmount USD amount covering the loan
     *  @param data Calltype data passed to Router contract.
     *  @return usdAmount The amount of USD deposited after taking into account liq. incentive
     *
     *  @custom:security non-reentrant
     */
    function liquidate(address collateral, address borrower, address receiver, uint256 repayAmount, bytes calldata data) external returns (uint256 usdAmount);

    /**
     *  @notice This public view function is used to get the borrow balance of users based on stored data
     *
     *  @param borrower The address whose balance should be calculated
     *
     *  @return principal The USD amount borrowed without interest accrual
     *  @return borrowBalance The USD amount borrowed with interest accrual (ie. USD amount the borrower must repay)
     */
    function getBorrowBalance(address collateral, address borrower) external view returns (uint256 principal, uint256 borrowBalance);

    /**
     *  @notice Applies interest accruals to borrows and reserves
     */
    function accrueInterest() external;

    /**
     *  @return underlying The address of the underlying (LP Token for collateral contracts, USDC for borrow contracts)
     */
    function underlying() external view returns (address);
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusCollateral.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

import {IERC20Permit} from "./IERC20Permit.sol";
import {IAllowanceTransfer} from "./IAllowanceTransfer.sol";

interface ICygnusCollateral is IERC20Permit { 
    /**
     *  @return underlying The address of the underlying (LP Token for collateral contracts, USDC for borrow contracts)
     */
    function underlying() external view returns (address);

    /**
     *  @return exchangeRate The ratio which 1 pool token can be redeemed for underlying amount.
     */
    function exchangeRate() external view returns (uint256);

    function borrowable() external view returns (address);

    /**
     *  @notice This function must be called with the `approve` method of the underlying asset token contract for
     *          the `assets` amount on behalf of the sender before calling this function.
     *  @notice Implements the deposit of the underlying asset into the Cygnus Vault pool. This function transfers
     *          the underlying assets from the sender to this contract and mints a corresponding amount of Cygnus
     *          Vault shares to the recipient. A deposit fee may be charged by the strategy, which is deducted from
     *          the deposited assets.
     *
     *  @dev If the deposit amount is less than or equal to 0, this function will revert.
     *
     *  @param assets Amount of the underlying asset to deposit.
     *  @param recipient Address that will receive the corresponding amount of shares.
     *  @param _permit Data signed over by the owner specifying the terms of approval
     *  @param _signature The owner's signature over the permit data
     *  @return shares Amount of Cygnus Vault shares minted and transferred to the `recipient`.
     */
    function deposit(
        uint256 assets,
        address recipient,
        IAllowanceTransfer.PermitSingle calldata _permit,
        bytes calldata _signature
    ) external returns (uint256 shares);

    /**
     *  @notice Flash redeems the underlying LP Token
     *
     *  @dev This should be called from `Altair` contract
     *
     *  @param redeemer The address redeeming the tokens (Altair contract)
     *  @param assets The amount of the underlying assets to redeem
     *  @param data Calldata passed from and back to router contract
     *
     *  @custom:security non-reentrant
     */
    function flashRedeemAltair(address redeemer, uint256 assets, bytes calldata data) external returns (uint256 usdAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)
pragma solidity >=0.8.17;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)
pragma solidity >=0.8.17;

import {IERC20} from "./IERC20.sol";

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit is IERC20 {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

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

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  IHangar18.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

/**
 *  @title The interface for the Cygnus Factory
 *  @notice The Cygnus factory facilitates creation of collateral and borrow pools
 */
interface IHangar18 {
    /**
     *  @return usd The address of the borrowable token (stablecoin)
     */
    function usd() external view returns (address);

    /**
     *  @return nativeToken The address of the chain's native token
     */
    function nativeToken() external view returns (address);

    /**
     *  @return admin The address of the Cygnus Admin which grants special permissions in collateral/borrow contracts
     */
    function admin() external view returns (address);

    /**
     *  @notice Array of LP Token pairs deployed
     *  @param _shuttleId The ID of the shuttle deployed
     *  @return launched Whether this pair exists or not
     *  @return shuttleId The ID of this shuttle
     *  @return borrowable The address of the borrow contract
     *  @return collateral The address of the collateral contract
     *  @return orbiterId The ID of the orbiters used to deploy this lending pool
     */
    function allShuttles(
        uint256 _shuttleId
    ) external view returns (bool launched, uint88 shuttleId, address borrowable, address collateral, uint96 orbiterId);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusAltair.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Interfaces
import {IERC20} from "./core/IERC20.sol";
import {IHangar18} from "./core/IHangar18.sol";
import {IWrappedNative} from "./IWrappedNative.sol";

// Permit2
import {IAllowanceTransfer} from "./core/IAllowanceTransfer.sol";
import {ISignatureTransfer} from "./core/ISignatureTransfer.sol";

/**
 *  @notice Interface to interact with Cygnus' router contract
 */
interface ICygnusAltair {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when the current block.timestamp is past deadline
     *
     *  @custom:error TransactionExpired
     */
    error CygnusAltair__TransactionExpired();

    /**
     *  @dev Reverts when the msg sender is not the cygnus factory admin
     *
     *  @custom:error MsgSenderNotAdmin
     */
    error CygnusAltair__MsgSenderNotAdmin();

    /**
     *  @dev Reverts when the paraswap transaction fails
     *
     *  @custom:error ParaswapTransactionFailed
     */
    error CygnusAltair__ParaswapTransactionFailed();

    /**
     *  @dev Reverts when the 1inch transaction fails
     *
     *  @custom:error OneInchTransactionFailed
     */
    error CygnusAltair__OneInchTransactionFailed();

    /**
     *  @dev Reverts when the 0x swap api transaction fails
     *
     *  @custom:error 0xProjectTransactionFailed
     */
    error CygnusAltair__0xProjectTransactionFailed();

    /**
     *  @dev Reverts if an extension has not been set for the borrowable or collateral
     *
     *  @custom:error AltairXDoesNotExist
     */
    error CygnusAltair__AltairXDoesNotExist();

    /**
     *  @dev Reverts if the shuttle does not exist when initializing an extension for it
     *
     *  @custom:erro ShuttleDoesNotExist
     */
    error CygnusAltair__ShuttleDoesNotExist();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Enum for choosing dex aggregators to perform leverage, deleverage and liquidations
     *  @custom:member PARASWAP Pass 0 to use Paraswap (most gas efficient)
     *  @custom:member ONE_INCH Pass 1 to use 1Inch legacy (using the `swap` function)
     *  @custom:member ONE_INCH Pass 2 to use 1Inch optimized routers (unoswap, uniswapv3, etc. - This can be the most gas consuming)
     *  @custom:member OxProject Pass 3 to use 0xProject/Matcha API
     */
    enum DexAggregator {
        PARASWAP,
        ONE_INCH_LEGACY,
        ONE_INCH_V2,
        OxPROJECT
    }

    /**
     *  @custom:struct AltairLeverageCalldata Encoded bytes passed to Cygnus Borrow contract for leverage
     *  @custom:member lpTokenPair The address of the LP Token
     *  @custom:member collateral The address of the Cygnus collateral contract
     *  @custom:member borrowable The address of the Cygnus borrow contract
     *  @custom:member recipient The address of the user receiving the leveraged LP Tokens
     *  @custom:member lpAmountMin The minimum amount of LP Tokens to receive
     */
    struct AltairLeverageCalldata {
        address lpTokenPair;
        address collateral;
        address borrowable;
        address recipient;
        uint256 lpAmountMin;
        DexAggregator dexAggregator;
        bytes[] swapdata;
    }

    /**
     *  @custom:struct AltairDeleverageCalldata Encoded bytes passed to Cygnus Collateral contract for de-leverage
     *  @custom:member lpTokenPair The address of the LP Token
     *  @custom:member collateral The address of the collateral contract
     *  @custom:member borrowable The address of the borrow contract
     *  @custom:member recipient The address of the user receiving the de-leveraged assets
     *  @custom:member redeemTokens The amount of CygLP to redeem
     *  @custom:member usdAmountMin The minimum amount of USD to receive by redeeming `redeemTokens`
     *  @custom:member swapdata The 1inch swap data byte array to convert Liquidity Tokens to USD
     */
    struct AltairDeleverageCalldata {
        address lpTokenPair;
        address collateral;
        address borrowable;
        address recipient;
        uint256 redeemTokens;
        uint256 usdAmountMin;
        DexAggregator dexAggregator;
        bytes[] swapdata;
    }

    /**
     *  @custom:struct AltairLiquidateCalldata Encoded bytes passed to Cygnus Borrow contract for liquidating borrows
     *  @custom:member lpTokenPair The address of the LP Token
     *  @custom:member collateral The address of the collateral contract
     *  @custom:member borrowable The address of the borrow contract
     *  @custom:member recipient The address of the liquidator (or this contract if protocol liquidation)
     *  @custom:member borrower The address of the borrower being liquidated
     *  @custom:member repayAmount The USD amount being repaid by the liquidator
     *  @custom:member swapdata The 1inch swap data byte array to convert Liquidity Tokens to USD after burning
     */
    struct AltairLiquidateCalldata {
        address lpTokenPair;
        address collateral;
        address borrowable;
        address recipient;
        address borrower;
        uint256 repayAmount;
        DexAggregator dexAggregator;
        bytes[] swapdata;
    }

    /**
     *  @notice Array of all initialized extensions
     */
    function allExtensions(uint256 index) external view returns (address);

    /**
     *  @return PERMIT Uniswap's Permit2 router
     */
    function PERMIT2() external view returns (address);

    /**
     *  @return PARASWAP_AUGUSTUS_SWAPPER_V5 The address of the Paraswap router used to perform the swaps
     */
    function PARASWAP_AUGUSTUS_SWAPPER_V5() external pure returns (address);

    /**
     *  @return ONE_INCH_ROUTER_V5 The address of the 1Inch router used to perform the swaps
     */
    function ONE_INCH_ROUTER_V5() external pure returns (address);

    /**
     *  @return OxPROJECT_EXCHANGE_PROXY The address of 0x's exchange proxy
     */
    function OxPROJECT_EXCHANGE_PROXY() external pure returns (address);

    /**
     *  @return name The human readable name this router is for
     */
    function name() external view returns (string memory);

    /**
     *  @return version The version of the router
     */
    function version() external view returns (string memory);

    /**
     *  @return hangar18 The address of the Cygnus factory contract V1 - Used to get the nativeToken and USD address
     */
    function hangar18() external view returns (IHangar18);

    /**
     *  @return usd The address of USD on this chain, used for the leverage/deleverage swaps
     */
    function usd() external view returns (address);

    /**
     *  @return nativeToken The address of the native token on this chain (ie. WETH)
     */
    function nativeToken() external view returns (IWrappedNative);

    /**
     *  @notice Returns the altair extension for a borrowable or collateral contract
     *  @param poolToken The address of a Cygnus borrowable or collateral or an lp token pair
     *  @return The address of the extension
     */
    function getAltairExtension(address poolToken) external view returns (address);

    /**
     *  @return altairExtensionsLength How many extensions we have added to the router so far
     */
    function altairExtensionsLength() external view returns (uint256);

    /**
     *  @dev Returns the assets and amounts received by redeeming a given amount of underlying liquidity tokens.
     *  @param underlying The address of the underlying liquidity token (e.g., LP token or Balancer BPT).
     *  @param shares The amount of underlying liquidity tokens to redeem.
     *  @return tokens An array of addresses representing the received tokens.
     *  @return amounts An array of corresponding amounts received by redeeming the liquidity tokens.
     */
    function getAssetsForShares(
        address underlying,
        uint256 shares,
        uint256 slippage
    ) external view returns (address[] memory tokens, uint256[] memory amounts);

    /**
     *  @dev Returns whether an extension is set or not
     *  @param extension The addres of CygnusAltairX
     */
    function isExtension(address extension) external returns (bool);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @notice Main function used in Cygnus to liquidate borrows
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The maximum amount to liquidate
     *  @param borrower The address of the borrower
     *  @param recipient The address of the recipient
     *  @param deadline The time by which the transaction must be included to effect the change
     */
    function liquidate(
        address collateral,
        address borrowable,
        uint256 amountMax,
        address borrower,
        address recipient,
        uint256 deadline,
        bytes calldata permitData
    ) external returns (uint256 amount, uint256 seizeTokens);

    /**
     *  @notice Main function used in Cygnus to liquidate borrows
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The maximum amount to liquidate
     *  @param borrower The address of the borrower
     *  @param recipient The address of the recipient
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param _permit Data signed over by the owner specifying the terms of approval
     *  @param signature The owner's signature over the permit data
     *  @return amount The amount of stablecoins repaid
     *  @return seizeTokens The amount of CygLP seized
     */
    function liquidatePermit2Allowance(
        address collateral,
        address borrowable,
        uint256 amountMax,
        address borrower,
        address recipient,
        uint256 deadline,
        IAllowanceTransfer.PermitSingle calldata _permit,
        bytes calldata signature
    ) external returns (uint256 amount, uint256 seizeTokens);

    /**
     *  @notice Main function used in Cygnus to liquidate borrows
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The maximum amount to liquidate
     *  @param borrower The address of the borrower
     *  @param recipient The address of the recipient
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param _permit Data signed over by the owner specifying the terms of approval
     *  @param signature The owner's signature over the permit data
     *  @return amount The amount of stablecoins repaid
     *  @return seizeTokens The amount of CygLP seized
     */
    function liquidatePermit2Signature(
        address collateral,
        address borrowable,
        uint256 amountMax,
        address borrower,
        address recipient,
        uint256 deadline,
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata signature
    ) external returns (uint256 amount, uint256 seizeTokens);

    /**
     *  @notice Main function used in Cygnus to borrow USD
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amount Amount of USD to borrow
     *  @param recipient The address of the borrower
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param permitData Permit data for pool token
     */
    function borrow(
        address collateral,
        address borrowable,
        uint256 amount,
        address recipient,
        uint256 deadline,
        bytes calldata permitData
    ) external;

    /**
     *  @notice Main function used in Cygnus to repay borrows
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The max amount to repay
     *  @param borrower Thea ddress of the borrower
     *  @param deadline The time by which the transaction must be included to effect the change
     */
    function repay(
        address collateral,
        address borrowable,
        uint256 amountMax,
        address borrower,
        uint256 deadline
    ) external returns (uint256 amount);

    /**
     *  @notice Main function used in Cygnus to repay borrow using Permit2 Signature Transfer
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The max amount to repay
     *  @param borrower Thea ddress of the borrower
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param _permit Data signed over by the owner specifying the terms of approval
     *  @param signature The owner's signature over the permit data
     */
    function repayPermit2Allowance(
        address collateral,
        address borrowable,
        uint256 amountMax,
        address borrower,
        uint256 deadline,
        IAllowanceTransfer.PermitSingle calldata _permit,
        bytes calldata signature
    ) external returns (uint256);

    /**
     *  @notice Main function used in Cygnus to repay borrow using Permit2 Signature Transfer
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The max amount to repay
     *  @param borrower Thea ddress of the borrower
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param _permit Data signed over by the owner specifying the terms of approval
     *  @param signature The owner's signature over the permit data
     */
    function repayPermit2Signature(
        address collateral,
        address borrowable,
        uint256 amountMax,
        address borrower,
        uint256 deadline,
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata signature
    ) external returns (uint256);

    /**
     *  @notice Main function to flash liquidate borrows. Ie, liquidating a user without needing to have USD
     *  @param borrowable The address of the CygnusBorrow contract
     *  @param amountMax The maximum amount to liquidate
     *  @param borrower The address of the borrower
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param dexAggregator The dex used to sell the collateral (0 for Paraswap, 1 for 1inch)
     *  @param swapdata Calldata to swap
     */
    function flashLiquidate(
        address borrowable,
        address collateral,
        uint256 amountMax,
        address borrower,
        uint256 deadline,
        DexAggregator dexAggregator,
        bytes[] calldata swapdata
    ) external returns (uint256 amount);

    /**
     *  @notice Main leverage function
     *  @param lpTokenPair The address of the LP Token
     *  @param collateral The address of the collateral of the lending pool
     *  @param borrowable The address of the borrowable of the lending pool
     *  @param usdAmount The amount to leverage
     *  @param lpAmountMin The minimum amount of LP Tokens to receive
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param permitData Permit data for borrowable leverage
     *  @param dexAggregator The dex used to sell the collateral (0 for Paraswap, 1 for 1inch)
     *  @param swapdata the 1inch swap data to convert USD to liquidity
     */
    function leverage(
        address lpTokenPair,
        address collateral,
        address borrowable,
        uint256 usdAmount,
        uint256 lpAmountMin,
        uint256 deadline,
        bytes calldata permitData,
        DexAggregator dexAggregator,
        bytes[] calldata swapdata
    ) external returns (uint256);

    /**
     *  @notice Main deleverage function
     *  @param lpTokenPair The address of the LP Token
     *  @param collateral The address of the collateral of the lending pool
     *  @param borrowable The address of the borrowable of the lending pool
     *  @param cygLPAmount The amount to CygLP to deleverage
     *  @param usdAmountMin The minimum amount of USD to receive
     *  @param deadline The time by which the transaction must be included to effect the change
     *  @param permitData Permit data for collateral deleverage
     *  @param dexAggregator The dex used to sell the collateral (0 for Paraswap, 1 for 1inch)
     *  @param swapdata the 1inch swap data to convert liquidity to USD
     */
    function deleverage(
        address lpTokenPair,
        address collateral,
        address borrowable,
        uint256 cygLPAmount,
        uint256 usdAmountMin,
        uint256 deadline,
        bytes calldata permitData,
        DexAggregator dexAggregator,
        bytes[] calldata swapdata
    ) external returns (uint256);

    /**
     *  @notice Initializes an extnesion of the router and maps it to a borrowable/collateral/lp token
     *  @param shuttleId the ID of the lending pool
     *  @param extension The address of the extension
     *  @custom:security only-admin
     */
    function setAltairExtension(uint256 shuttleId, address extension) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusAltairCall.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

/**
 *  @title ICygnusAltairCall
 *  @notice Simple callee contract for leverage, deleverage and flash liquidations (see CygnusBorrow.sol)
 */
interface ICygnusAltairCall {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /**
     *  @notice Function that is called by the CygnusBorrow contract and decodes data to carry out the leverage
     *  @notice Will only succeed if: Caller is borrow contract & Borrow contract was called by router
     *
     *  @param sender Address of the contract that initialized the borrow transaction (address of the router)
     *  @param borrowAmount The amount to leverage
     *  @param data The encoded byte data passed from the CygnusBorrow contract to the router
     */
    function altairBorrow_O9E(address sender, uint256 borrowAmount, bytes calldata data) external returns (uint256 liquidity);

    /**
     *  @notice Function that is called by the CygnusCollateral contract and decodes data to carry out the deleverage
     *  @notice Will only succeed if: Caller is collateral contract & collateral contract was called by router
     *
     *  @param sender Address of the contract that initialized the redeem transaction (address of the router)
     *  @param redeemAmount The amount to deleverage
     *  @param data The encoded byte data passed from the CygnusCollateral contract to the router
     */
    function altairRedeem_u91A(address sender, uint256 redeemAmount, bytes calldata data) external returns (uint256 usdAmount);

    /**
     *  @notice Function that is called by the CygnusBorrow contract and decodes data to carry out the liquidation
     *  @notice Will only succeed if: Caller is borrow contract & Borrow contract was called by router
     *
     *  @param sender Address of the contract that initialized the borrow transaction (address of the router)
     *  @param cygLPAmount The cygLP Amount seized
     *  @param actualRepayAmount The usd amount the contract must have for the liquidate function to finish
     *  @param data The encoded byte data passed from the CygnusBorrow contract to the router
     */
    function altairLiquidate_f2x(address sender, uint256 cygLPAmount, uint256 actualRepayAmount, bytes calldata data) external;
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  ICygnusAltairX.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

// Interfaces
import {IERC20} from "./core/IERC20.sol";
import {IHangar18} from "./core/IHangar18.sol";
import {IWrappedNative} from "./IWrappedNative.sol";

/**
 *  @notice Interface to interact with Cygnus' router contract
 */
interface ICygnusAltairX {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. CUSTOM ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @dev Reverts when the msg sender is not the collateral contract
     *
     *  @custom:error MsgSenderNotCollateral
     */
    error CygnusAltair__MsgSenderNotCollateral();

    /**
     *  @dev Reverts when the msg sender is not the router in the leverage function
     *
     *  @custom:error MsgSenderNotRouter
     */
    error CygnusAltair__MsgSenderNotRouter();

    /**
     *  @dev Reverts when the msg sender is not the borrow contract
     *
     *  @custom:error MsgSenderNotBorrowable
     */
    error CygnusAltair__MsgSenderNotBorrowable();

    /**
     *  @dev Reverts when the paraswap transaction fails
     *
     *  @custom:error ParaswapTransactionFailed
     */
    error CygnusAltair__ParaswapTransactionFailed();

    /**
     *  @dev Reverts when the 1inch transaction fails
     *
     *  @custom:error OneInchTransactionFailed
     */
    error CygnusAltair__OneInchTransactionFailed();

    /**
     *  @dev Reverts when the 0x swap api transaction fails
     *
     *  @custom:error 0xProjectTransactionFailed
     */
    error CygnusAltair__0xProjectTransactionFailed();

    /**
     *  @dev Reverts when USD amount received is less than minimum asked while liquidating
     *
     *  @custom:error InsufficientLiquidateUsd
     */
    error CygnusAltair__InsufficientLiquidateUsd();

    /**
     *  @dev Reverts when amount of USD received is less than the minimum asked
     *
     *  @custom:error InsufficientUSDAmount
     */
    error CygnusAltair__InsufficientUSDAmount();

    /**
     *  @dev Reverts when the swapped amount is less than the min requested
     *
     *  @custom:error InsufficientLPTokenAmount
     */
    error CygnusAltair__InsufficientLPTokenAmount();

    /**
     *  @dev Reverts if the call is not a delegate call
     *
     *  @custom:error OnlyDelegateCall
     */
    error CygnusAltair__OnlyDelegateCall();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /**
     *  @return name The human readable name this router is for
     */
    function name() external view returns (string memory);

    /**
     *  @return PERMIT Uniswap's Permit2 router
     */
    function PERMIT2() external view returns (address);

    /**
     *  @return PARASWAP_AUGUSTUS_SWAPPER_V5 The address of the Paraswap router used to perform the swaps
     */
    function PARASWAP_AUGUSTUS_SWAPPER_V5() external pure returns (address);

    /**
     *  @return ONE_INCH_ROUTER_V5 The address of the 1Inch router used to perform the swaps
     */
    function ONE_INCH_ROUTER_V5() external pure returns (address);

    /**
     *  @return OxPROJECT_EXCHANGE_PROXY The address of 0x's exchange proxy
     */
    function OxPROJECT_EXCHANGE_PROXY() external pure returns (address);

    /**
     *  @return hangar18 The address of the Cygnus factory contract V1 - Used to get the nativeToken and USD address
     */
    function hangar18() external view returns (IHangar18);

    /**
     *  @return usd The address of USD on this chain, used for the leverage/deleverage swaps
     */
    function usd() external view returns (address);

    /**
     *  @return nativeToken The address of the native token on this chain (ie. WETH)
     */
    function nativeToken() external view returns (IWrappedNative);

    /**
     *  @dev Returns the assets and amounts received by redeeming a given amount of underlying liquidity tokens.
     *  @param underlying The address of the underlying liquidity token (e.g., LP token or Balancer BPT).
     *  @param shares The amount of underlying liquidity tokens to redeem.
     *  @return tokens An array of addresses representing the received tokens.
     *  @return amounts An array of corresponding amounts received by redeeming the liquidity tokens.
     */
    function getAssetsForShares(
        address underlying,
        uint256 shares,
        uint256 slippage
    ) external view returns (address[] memory tokens, uint256[] memory amounts);

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.17;

// Interface for interfacting with Wrapped Eth
interface IWrappedNative {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function approve(address to, uint256 value) external returns (bool);
}

//  SPDX-License-Identifier: AGPL-3.0-or-later
//
//  CygnusDexLib.sol
//
//  Copyright (C) 2023 CygnusDAO
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity >=0.8.17;

import {FixedPointMathLib} from "./FixedPointMathLib.sol";

library CygnusDexLib {
    using FixedPointMathLib for uint256;

    /**
     *  @dev Compute optimal deposit amount (https://blog.alphaventuredao.io/onesideduniswap/)
     *  @param amountA amount of token A desired to deposit
     *  @param reservesA Reserves of token A from the DEX
     *  @param swapFee The fee charged by this dex for a swap (ie Uniswap = 997/1000 = 0.3%)
     *  @return optimal swap amount of tokenA to tokenB to then hold the same proportion of assets as in pool reserves
     */
    function optimalDepositA(uint256 amountA, uint256 reservesA, uint256 swapFee) internal pure returns (uint256) {
        // Calculate with dex swap fee
        uint256 _swapFee = 10000 - swapFee;
        uint256 a = (10000 + _swapFee) * reservesA;
        uint256 b = amountA * 10000 * reservesA * 4 * _swapFee;
        uint256 c = FixedPointMathLib.sqrt(a * a + b);
        uint256 d = 2 * _swapFee;
        return (c - a) / d;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /// @dev The output is undefined, as the input is zero.
    error Log2Undefined();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
                // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
                if iszero(slt(x, 135305999368893231589)) {
                    // Store the function selector of `ExpOverflow()`.
                    mstore(0x00, 0xa37bfec9)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            /// @solidity memory-safe-assembly
            assembly {
                if iszero(sgt(x, 0)) {
                    // Store the function selector of `LnWadUndefined()`.
                    mstore(0x00, 0x1615e638)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96.
            int256 k;
            /// @solidity memory-safe-assembly
            assembly {
                let v := x
                k := shl(7, lt(0xffffffffffffffffffffffffffffffff, v))
                k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, v))))
                k := or(k, shl(5, lt(0xffffffff, shr(k, v))))

                // For the remaining 32 bits, use a De Bruijn lookup.
                // See: https://graphics.stanford.edu/~seander/bithacks.html
                v := shr(k, v)
                v := or(v, shr(1, v))
                v := or(v, shr(2, v))
                v := or(v, shr(4, v))
                v := or(v, shr(8, v))
                v := or(v, shr(16, v))

                // forgefmt: disable-next-item
                k := sub(
                    or(k, byte(shr(251, mul(v, shl(224, 0x07c4acdd))), 0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f)),
                    96
                )
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Calculates `floor(a * b / d)` with full precision.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {

            } 1 {

            } {
                // 512-bit multiply `[prod1 prod0] = x * y`.
                // Compute the product mod `2**256` and mod `2**256 - 1`
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that `product = prod1 * 2**256 + prod0`.

                // Least significant 256 bits of the product.
                let prod0 := mul(x, y)
                let mm := mulmod(x, y, not(0))
                // Most significant 256 bits of the product.
                let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(prod1) {
                    if iszero(d) {
                        // Store the function selector of `FullMulDivFailed()`.
                        mstore(0x00, 0xae47f702)
                        // Revert with (offset, size).
                        revert(0x1c, 0x04)
                    }
                    result := div(prod0, d)
                    break
                }

                // Make sure the result is less than `2**256`.
                // Also prevents `d == 0`.
                if iszero(gt(d, prod1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }

                ///////////////////////////////////////////////
                // 512 by 256 division.
                ///////////////////////////////////////////////

                // Make division exact by subtracting the remainder from `[prod1 prod0]`.
                // Compute remainder using mulmod.
                let remainder := mulmod(x, y, d)
                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
                // Factor powers of two out of `d`.
                // Compute largest power of two divisor of `d`.
                // Always greater or equal to 1.
                let twos := and(d, sub(0, d))
                // Divide d by power of two.
                d := div(d, twos)
                // Divide [prod1 prod0] by the factors of two.
                prod0 := div(prod0, twos)
                // Shift in bits from `prod1` into `prod0`. For this we need
                // to flip `twos` such that it is `2**256 / twos`.
                // If `twos` is zero, then it becomes one.
                prod0 := or(prod0, mul(prod1, add(div(sub(0, twos), twos), 1)))
                // Invert `d mod 2**256`
                // Now that `d` is an odd number, it has an inverse
                // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                let inv := xor(mul(3, d), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                result := mul(prod0, mul(inv, sub(2, mul(d, inv)))) // inverse mod 2**256
                break
            }
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        result = fullMulDiv(x, y, d);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(x, y, d) {
                if iszero(add(result, 1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
                result := add(result, 1)
            }
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), d)
        }
    }

    /// @dev Returns `ceil(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
        }
    }

    /// @dev Returns `ceil(x / d)`.
    /// Reverts if `d` is zero.
    function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(d) {
                // Store the function selector of `DivFailed()`.
                mstore(0x00, 0x65244e4e)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, d))), div(x, d))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`.
            // We check `y >= 2**(k + 8)` but shift right by `k` bits
            // each branch to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {

            } 1 {

            } {
                if iszero(lt(10, x)) {
                    // forgefmt: disable-next-item
                    result := and(shr(mul(22, x), 0x375f0016260009d80004ec0002d00001e0000180000180000200000400001), 0x3fffff)
                    break
                }
                if iszero(lt(57, x)) {
                    let end := 31
                    result := 8222838654177922817725562880000000
                    if iszero(lt(end, x)) {
                        end := 10
                        result := 3628800
                    }
                    for {
                        let w := not(0)
                    } 1 {

                    } {
                        result := mul(result, x)
                        x := add(x, w)
                        if eq(x, end) {
                            break
                        }
                    }
                    break
                }
                // Store the function selector of `FactorialOverflow()`.
                mstore(0x00, 0xaba0f2a2)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(x) {
                // Store the function selector of `Log2Undefined()`.
                mstore(0x00, 0x5be3aa5c)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // See: https://graphics.stanford.edu/~seander/bithacks.html
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            // forgefmt: disable-next-item
            r := or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))), 0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        unchecked {
            uint256 isNotPo2;
            assembly {
                isNotPo2 := iszero(iszero(and(x, sub(x, 1))))
            }
            return log2(x) + isNotPo2;
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = (x & y) + ((x ^ y) >> 1);
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1);
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let a := sub(y, x)
            z := xor(a, mul(xor(a, sub(x, y)), sgt(x, y)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue) internal pure returns (uint256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns greatest common divisor of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {
                z := x
            } y {

            } {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   RAW NUMBER OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
    }

    /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
    function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, d)
        }
    }

    /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
    function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, d)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // For better gas estimation.
                    if iszero(gt(gas(), 1000000)) {
                        revert(0, 0)
                    }
                }
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overriden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                if iszero(create(amount, 0x0b, 0x16)) {
                    // For better gas estimation.
                    if iszero(gt(gas(), 1000000)) {
                        revert(0, 0)
                    }
                }
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal returns (bool success) {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x0c, 0x23b872dd000000000000000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x0c, 0x70a08231000000000000000000000000)
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            // The `amount` argument is already written to the memory word at 0x6c.
            amount := mload(0x60)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x14, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x34.
            amount := mload(0x34)
            // Store the function selector of `transfer(address,uint256)`.
            mstore(0x00, 0xa9059cbb000000000000000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`.
            mstore(0x00, 0x095ea7b3000000000000000000000000)

            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten.
            mstore(0x34, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            // Store the function selector of `balanceOf(address)`.
            mstore(0x00, 0x70a08231000000000000000000000000)
            amount := mul(
                mload(0x20),
                and(
                    // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                )
            )
        }
    }
}