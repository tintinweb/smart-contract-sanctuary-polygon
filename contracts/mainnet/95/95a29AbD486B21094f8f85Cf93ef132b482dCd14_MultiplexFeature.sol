// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/src/IERC20Token.sol";
import "@0x/contracts-erc20/src/IEtherToken.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../external/ILiquidityProviderSandbox.sol";
import "../../fixins/FixinCommon.sol";
import "../../fixins/FixinEIP712.sol";
import "../../migrations/LibMigrate.sol";
import "../interfaces/IFeature.sol";
import "../interfaces/IMultiplexFeature.sol";
import "./MultiplexLiquidityProvider.sol";
import "./MultiplexOtc.sol";
import "./MultiplexRfq.sol";
import "./MultiplexTransformERC20.sol";
import "./MultiplexUniswapV2.sol";
import "./MultiplexUniswapV3.sol";

/// @dev This feature enables efficient batch and multi-hop trades
///      using different liquidity sources.
contract MultiplexFeature is
    IFeature,
    IMultiplexFeature,
    FixinCommon,
    MultiplexLiquidityProvider,
    MultiplexOtc,
    MultiplexRfq,
    MultiplexTransformERC20,
    MultiplexUniswapV2,
    MultiplexUniswapV3
{
    /// @dev Name of this feature.
    string public constant override FEATURE_NAME = "MultiplexFeature";
    /// @dev Version of this feature.
    uint256 public immutable override FEATURE_VERSION = _encodeVersion(2, 0, 0);
    /// @dev The highest bit of a uint256 value.
    uint256 private constant HIGH_BIT = 2 ** 255;
    /// @dev Mask of the lower 255 bits of a uint256 value.
    uint256 private constant LOWER_255_BITS = HIGH_BIT - 1;

    /// @dev The WETH token contract.
    IEtherToken private immutable WETH;

    constructor(
        address zeroExAddress,
        IEtherToken weth,
        ILiquidityProviderSandbox sandbox,
        address uniswapFactory,
        address sushiswapFactory,
        bytes32 uniswapPairInitCodeHash,
        bytes32 sushiswapPairInitCodeHash
    )
        public
        FixinEIP712(zeroExAddress)
        MultiplexLiquidityProvider(sandbox)
        MultiplexUniswapV2(uniswapFactory, sushiswapFactory, uniswapPairInitCodeHash, sushiswapPairInitCodeHash)
    {
        WETH = weth;
    }

    /// @dev Initialize and register this feature.
    ///      Should be delegatecalled by `Migrate.migrate()`.
    /// @return success `LibMigrate.SUCCESS` on success.
    function migrate() external returns (bytes4 success) {
        _registerFeatureFunction(this.multiplexBatchSellEthForToken.selector);
        _registerFeatureFunction(this.multiplexBatchSellTokenForEth.selector);
        _registerFeatureFunction(this.multiplexBatchSellTokenForToken.selector);
        _registerFeatureFunction(this._multiplexBatchSell.selector);
        _registerFeatureFunction(this.multiplexMultiHopSellEthForToken.selector);
        _registerFeatureFunction(this.multiplexMultiHopSellTokenForEth.selector);
        _registerFeatureFunction(this.multiplexMultiHopSellTokenForToken.selector);
        _registerFeatureFunction(this._multiplexMultiHopSell.selector);
        return LibMigrate.MIGRATE_SUCCESS;
    }

    /// @dev Sells attached ETH for `outputToken` using the provided
    ///      calls.
    /// @param outputToken The token to buy.
    /// @param calls The calls to use to sell the attached ETH.
    /// @param minBuyAmount The minimum amount of `outputToken` that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function multiplexBatchSellEthForToken(
        IERC20Token outputToken,
        BatchSellSubcall[] memory calls,
        uint256 minBuyAmount
    ) public payable override returns (uint256 boughtAmount) {
        // Wrap ETH.
        WETH.deposit{value: msg.value}();
        // WETH is now held by this contract,
        // so `useSelfBalance` is true.
        return
            _multiplexBatchSellPrivate(
                BatchSellParams({
                    inputToken: WETH,
                    outputToken: outputToken,
                    sellAmount: msg.value,
                    calls: calls,
                    useSelfBalance: true,
                    recipient: msg.sender,
                    payer: msg.sender
                }),
                minBuyAmount
            );
    }

    /// @dev Sells `sellAmount` of the given `inputToken` for ETH
    ///      using the provided calls.
    /// @param inputToken The token to sell.
    /// @param calls The calls to use to sell the input tokens.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of ETH that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of ETH bought.
    function multiplexBatchSellTokenForEth(
        IERC20Token inputToken,
        BatchSellSubcall[] memory calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        // The outputToken is implicitly WETH. The `recipient`
        // of the WETH is set to  this contract, since we
        // must unwrap the WETH and transfer the resulting ETH.
        boughtAmount = _multiplexBatchSellPrivate(
            BatchSellParams({
                inputToken: inputToken,
                outputToken: WETH,
                sellAmount: sellAmount,
                calls: calls,
                useSelfBalance: false,
                recipient: address(this),
                payer: msg.sender
            }),
            minBuyAmount
        );
        // Unwrap WETH.
        WETH.withdraw(boughtAmount);
        // Transfer ETH to `msg.sender`.
        _transferEth(msg.sender, boughtAmount);
    }

    /// @dev Sells `sellAmount` of the given `inputToken` for
    ///      `outputToken` using the provided calls.
    /// @param inputToken The token to sell.
    /// @param outputToken The token to buy.
    /// @param calls The calls to use to sell the input tokens.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of `outputToken`
    ///        that must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function multiplexBatchSellTokenForToken(
        IERC20Token inputToken,
        IERC20Token outputToken,
        BatchSellSubcall[] memory calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        return
            _multiplexBatchSellPrivate(
                BatchSellParams({
                    inputToken: inputToken,
                    outputToken: outputToken,
                    sellAmount: sellAmount,
                    calls: calls,
                    useSelfBalance: false,
                    recipient: msg.sender,
                    payer: msg.sender
                }),
                minBuyAmount
            );
    }

    /// @dev Executes a batch sell and checks that at least
    ///      `minBuyAmount` of `outputToken` was bought. Internal variant.
    /// @param params Batch sell parameters.
    /// @param minBuyAmount The minimum amount of `outputToken` that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function _multiplexBatchSell(
        BatchSellParams memory params,
        uint256 minBuyAmount
    ) public override onlySelf returns (uint256 boughtAmount) {
        return _multiplexBatchSellPrivate(params, minBuyAmount);
    }

    /// @dev Executes a batch sell and checks that at least
    ///      `minBuyAmount` of `outputToken` was bought.
    /// @param params Batch sell parameters.
    /// @param minBuyAmount The minimum amount of `outputToken` that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function _multiplexBatchSellPrivate(
        BatchSellParams memory params,
        uint256 minBuyAmount
    ) private returns (uint256 boughtAmount) {
        // Cache the recipient's initial balance of the output token.
        uint256 balanceBefore = params.outputToken.balanceOf(params.recipient);
        // Execute the batch sell.
        BatchSellState memory state = _executeBatchSell(params);
        // Compute the change in balance of the output token.
        uint256 balanceDelta = params.outputToken.balanceOf(params.recipient).safeSub(balanceBefore);
        // Use the minimum of the balanceDelta and the returned bought
        // amount in case of weird tokens and whatnot.
        boughtAmount = LibSafeMathV06.min256(balanceDelta, state.boughtAmount);
        // Enforce `minBuyAmount`.
        require(boughtAmount >= minBuyAmount, "MultiplexFeature::_multiplexBatchSell/UNDERBOUGHT");
    }

    /// @dev Sells attached ETH via the given sequence of tokens
    ///      and calls. `tokens[0]` must be WETH.
    ///      The last token in `tokens` is the output token that
    ///      will ultimately be sent to `msg.sender`
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function multiplexMultiHopSellEthForToken(
        address[] memory tokens,
        MultiHopSellSubcall[] memory calls,
        uint256 minBuyAmount
    ) public payable override returns (uint256 boughtAmount) {
        // First token must be WETH.
        require(tokens[0] == address(WETH), "MultiplexFeature::multiplexMultiHopSellEthForToken/NOT_WETH");
        // Wrap ETH.
        WETH.deposit{value: msg.value}();
        // WETH is now held by this contract,
        // so `useSelfBalance` is true.
        return
            _multiplexMultiHopSellPrivate(
                MultiHopSellParams({
                    tokens: tokens,
                    sellAmount: msg.value,
                    calls: calls,
                    useSelfBalance: true,
                    recipient: msg.sender,
                    payer: msg.sender
                }),
                minBuyAmount
            );
    }

    /// @dev Sells `sellAmount` of the input token (`tokens[0]`)
    ///      for ETH via the given sequence of tokens and calls.
    ///      The last token in `tokens` must be WETH.
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of ETH that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of ETH bought.
    function multiplexMultiHopSellTokenForEth(
        address[] memory tokens,
        MultiHopSellSubcall[] memory calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        // Last token must be WETH.
        require(
            tokens[tokens.length - 1] == address(WETH),
            "MultiplexFeature::multiplexMultiHopSellTokenForEth/NOT_WETH"
        );
        // The `recipient of the WETH is set to  this contract, since
        // we must unwrap the WETH and transfer the resulting ETH.
        boughtAmount = _multiplexMultiHopSellPrivate(
            MultiHopSellParams({
                tokens: tokens,
                sellAmount: sellAmount,
                calls: calls,
                useSelfBalance: false,
                recipient: address(this),
                payer: msg.sender
            }),
            minBuyAmount
        );
        // Unwrap WETH.
        WETH.withdraw(boughtAmount);
        // Transfer ETH to `msg.sender`.
        _transferEth(msg.sender, boughtAmount);
    }

    /// @dev Sells `sellAmount` of the input token (`tokens[0]`)
    ///      via the given sequence of tokens and calls.
    ///      The last token in `tokens` is the output token that
    ///      will ultimately be sent to `msg.sender`
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function multiplexMultiHopSellTokenForToken(
        address[] memory tokens,
        MultiHopSellSubcall[] memory calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) public override returns (uint256 boughtAmount) {
        return
            _multiplexMultiHopSellPrivate(
                MultiHopSellParams({
                    tokens: tokens,
                    sellAmount: sellAmount,
                    calls: calls,
                    useSelfBalance: false,
                    recipient: msg.sender,
                    payer: msg.sender
                }),
                minBuyAmount
            );
    }

    /// @dev Executes a multi-hop sell. Internal variant.
    /// @param params Multi-hop sell parameters.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function _multiplexMultiHopSell(
        MultiHopSellParams memory params,
        uint256 minBuyAmount
    ) public override onlySelf returns (uint256 boughtAmount) {
        return _multiplexMultiHopSellPrivate(params, minBuyAmount);
    }

    /// @dev Executes a multi-hop sell and checks that at least
    ///      `minBuyAmount` of output tokens were bought.
    /// @param params Multi-hop sell parameters.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function _multiplexMultiHopSellPrivate(
        MultiHopSellParams memory params,
        uint256 minBuyAmount
    ) private returns (uint256 boughtAmount) {
        // There should be one call/hop between every two tokens
        // in the path.
        // tokens[0]b b calls[0]b b >tokens[1]b b ...b b calls[n-1]b b >tokens[n]
        require(
            params.tokens.length == params.calls.length + 1,
            "MultiplexFeature::_multiplexMultiHopSell/MISMATCHED_ARRAY_LENGTHS"
        );
        // The output token is the last token in the path.
        IERC20Token outputToken = IERC20Token(params.tokens[params.tokens.length - 1]);
        // Cache the recipient's balance of the output token.
        uint256 balanceBefore = outputToken.balanceOf(params.recipient);
        // Execute the multi-hop sell.
        MultiHopSellState memory state = _executeMultiHopSell(params);
        // Compute the change in balance of the output token.
        uint256 balanceDelta = outputToken.balanceOf(params.recipient).safeSub(balanceBefore);
        // Use the minimum of the balanceDelta and the returned bought
        // amount in case of weird tokens and whatnot.
        boughtAmount = LibSafeMathV06.min256(balanceDelta, state.outputTokenAmount);
        // Enforce `minBuyAmount`.
        require(boughtAmount >= minBuyAmount, "MultiplexFeature::_multiplexMultiHopSell/UNDERBOUGHT");
    }

    /// @dev Iterates through the constituent calls of a batch
    ///      sell and executes each one, until the full amount
    //       has been sold.
    /// @param params Batch sell parameters.
    /// @return state A struct containing the amounts of `inputToken`
    ///         sold and `outputToken` bought.
    function _executeBatchSell(BatchSellParams memory params) private returns (BatchSellState memory state) {
        // Iterate through the calls and execute each one
        // until the full amount has been sold.
        for (uint256 i = 0; i != params.calls.length; i++) {
            // Check if we've hit our target.
            if (state.soldAmount >= params.sellAmount) {
                break;
            }
            BatchSellSubcall memory subcall = params.calls[i];
            // Compute the input token amount.
            uint256 inputTokenAmount = _normalizeSellAmount(subcall.sellAmount, params.sellAmount, state.soldAmount);
            if (subcall.id == MultiplexSubcall.RFQ) {
                _batchSellRfqOrder(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.OTC) {
                _batchSellOtcOrder(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.UniswapV2) {
                _batchSellUniswapV2(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.UniswapV3) {
                _batchSellUniswapV3(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.LiquidityProvider) {
                _batchSellLiquidityProvider(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.TransformERC20) {
                _batchSellTransformERC20(state, params, subcall.data, inputTokenAmount);
            } else if (subcall.id == MultiplexSubcall.MultiHopSell) {
                _nestedMultiHopSell(state, params, subcall.data, inputTokenAmount);
            } else {
                revert("MultiplexFeature::_executeBatchSell/INVALID_SUBCALL");
            }
        }
        require(state.soldAmount == params.sellAmount, "MultiplexFeature::_executeBatchSell/INCORRECT_AMOUNT_SOLD");
    }

    // This function executes a sequence of fills "hopping" through the
    // path of tokens given by `params.tokens`.
    function _executeMultiHopSell(MultiHopSellParams memory params) private returns (MultiHopSellState memory state) {
        // This variable is used for the input and output amounts of
        // each hop. After the final hop, this will contain the output
        // amount of the multi-hop fill.
        state.outputTokenAmount = params.sellAmount;
        // The first call may expect the input tokens to be held by
        // `payer`, `address(this)`, or some other address.
        // Compute the expected address and transfer the input tokens
        // there if necessary.
        state.from = _computeHopTarget(params, 0);
        // If the input tokens are currently held by `payer` but
        // the first hop expects them elsewhere, perform a `transferFrom`.
        if (!params.useSelfBalance && state.from != params.payer) {
            _transferERC20TokensFrom(IERC20Token(params.tokens[0]), params.payer, state.from, params.sellAmount);
        }
        // If the input tokens are currently held by `address(this)` but
        // the first hop expects them elsewhere, perform a `transfer`.
        if (params.useSelfBalance && state.from != address(this)) {
            _transferERC20Tokens(IERC20Token(params.tokens[0]), state.from, params.sellAmount);
        }
        // Iterate through the calls and execute each one.
        for (state.hopIndex = 0; state.hopIndex != params.calls.length; state.hopIndex++) {
            MultiHopSellSubcall memory subcall = params.calls[state.hopIndex];
            // Compute the recipient of the tokens that will be
            // bought by the current hop.
            state.to = _computeHopTarget(params, state.hopIndex + 1);

            if (subcall.id == MultiplexSubcall.UniswapV2) {
                _multiHopSellUniswapV2(state, params, subcall.data);
            } else if (subcall.id == MultiplexSubcall.UniswapV3) {
                _multiHopSellUniswapV3(state, params, subcall.data);
            } else if (subcall.id == MultiplexSubcall.LiquidityProvider) {
                _multiHopSellLiquidityProvider(state, params, subcall.data);
            } else if (subcall.id == MultiplexSubcall.BatchSell) {
                _nestedBatchSell(state, params, subcall.data);
            } else if (subcall.id == MultiplexSubcall.OTC) {
                _multiHopSellOtcOrder(state, params, subcall.data);
            } else {
                revert("MultiplexFeature::_executeMultiHopSell/INVALID_SUBCALL");
            }
            // The recipient of the current hop will be the source
            // of tokens for the next hop.
            state.from = state.to;
        }
    }

    function _nestedMultiHopSell(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory data,
        uint256 sellAmount
    ) private {
        MultiHopSellParams memory multiHopParams;
        // Decode the tokens and calls for the nested
        // multi-hop sell.
        (multiHopParams.tokens, multiHopParams.calls) = abi.decode(data, (address[], MultiHopSellSubcall[]));
        multiHopParams.sellAmount = sellAmount;
        // If the batch sell is using input tokens held by
        // `address(this)`, then so should the nested
        // multi-hop sell.
        multiHopParams.useSelfBalance = params.useSelfBalance;
        // Likewise, the recipient of the multi-hop sell is
        // equal to the recipient of its containing batch sell.
        multiHopParams.recipient = params.recipient;
        // The payer is the same too.
        multiHopParams.payer = params.payer;
        // Execute the nested multi-hop sell.
        uint256 outputTokenAmount = _executeMultiHopSell(multiHopParams).outputTokenAmount;
        // Increment the sold and bought amounts.
        state.soldAmount = state.soldAmount.safeAdd(sellAmount);
        state.boughtAmount = state.boughtAmount.safeAdd(outputTokenAmount);
    }

    function _nestedBatchSell(
        IMultiplexFeature.MultiHopSellState memory state,
        IMultiplexFeature.MultiHopSellParams memory params,
        bytes memory data
    ) private {
        BatchSellParams memory batchSellParams;
        // Decode the calls for the nested batch sell.
        batchSellParams.calls = abi.decode(data, (BatchSellSubcall[]));
        // The input and output tokens of the batch
        // sell are the current and next tokens in
        // `params.tokens`, respectively.
        batchSellParams.inputToken = IERC20Token(params.tokens[state.hopIndex]);
        batchSellParams.outputToken = IERC20Token(params.tokens[state.hopIndex + 1]);
        // The `sellAmount` for the batch sell is the
        // `outputTokenAmount` from the previous hop.
        batchSellParams.sellAmount = state.outputTokenAmount;
        // If the nested batch sell is the first hop
        // and `useSelfBalance` for the containing multi-
        // hop sell is false, the nested batch sell should
        // pull tokens from `payer` (so  `batchSellParams.useSelfBalance`
        // should be false). Otherwise `batchSellParams.useSelfBalance`
        // should be true.
        batchSellParams.useSelfBalance = state.hopIndex > 0 || params.useSelfBalance;
        // `state.to` has been populated with the address
        // that should receive the output tokens of the
        // batch sell.
        batchSellParams.recipient = state.to;
        // payer shound be the same too.
        batchSellParams.payer = params.payer;
        // Execute the nested batch sell.
        state.outputTokenAmount = _executeBatchSell(batchSellParams).boughtAmount;
    }

    // This function computes the "target" address of hop index `i` within
    // a multi-hop sell.
    // If `i == 0`, the target is the address which should hold the input
    // tokens prior to executing `calls[0]`. Otherwise, it is the address
    // that should receive `tokens[i]` upon executing `calls[i-1]`.
    function _computeHopTarget(MultiHopSellParams memory params, uint256 i) private view returns (address target) {
        if (i == params.calls.length) {
            // The last call should send the output tokens to the
            // multi-hop sell recipient.
            target = params.recipient;
        } else {
            MultiHopSellSubcall memory subcall = params.calls[i];
            if (subcall.id == MultiplexSubcall.UniswapV2) {
                // UniswapV2 (and Sushiswap) allow tokens to be
                // transferred into the pair contract before `swap`
                // is called, so we compute the pair contract's address.
                (address[] memory tokens, bool isSushi) = abi.decode(subcall.data, (address[], bool));
                target = _computeUniswapPairAddress(tokens[0], tokens[1], isSushi);
            } else if (subcall.id == MultiplexSubcall.LiquidityProvider) {
                // Similar to UniswapV2, LiquidityProvider contracts
                // allow tokens to be transferred in before the swap
                // is executed, so we the target is the address encoded
                // in the subcall data.
                (target, ) = abi.decode(subcall.data, (address, bytes));
            } else if (
                subcall.id == MultiplexSubcall.UniswapV3 ||
                subcall.id == MultiplexSubcall.BatchSell ||
                subcall.id == MultiplexSubcall.OTC
            ) {
                // UniswapV3 uses a callback to pull in the tokens being
                // sold to it. The callback implemented in `UniswapV3Feature`
                // can either:
                // - call `transferFrom` to move tokens from `payer` to the
                //   UniswapV3 pool, or
                // - call `transfer` to move tokens from `address(this)` to the
                //   UniswapV3 pool.
                // A nested batch sell is similar, in that it can either:
                // - use tokens from `payer`, or
                // - use tokens held by `address(this)`.

                // Suppose UniswapV3/BatchSell is the first call in the multi-hop
                // path. The input tokens are either held by `payer`,
                // or in the case of `multiplexMultiHopSellEthForToken` WETH is
                // held by `address(this)`. The target is set accordingly.

                // If this is _not_ the first call in the multi-hop path, we
                // are dealing with an "intermediate" token in the multi-hop path,
                // which `payer` may not have an allowance set for. Thus
                // target must be set to `address(this)` for `i > 0`.
                if (i == 0 && !params.useSelfBalance) {
                    target = params.payer;
                } else {
                    target = address(this);
                }
            } else {
                revert("MultiplexFeature::_computeHopTarget/INVALID_SUBCALL");
            }
        }
        require(target != address(0), "MultiplexFeature::_computeHopTarget/TARGET_IS_NULL");
    }

    // If `rawAmount` encodes a proportion of `totalSellAmount`, this function
    // converts it to an absolute quantity. Caps the normalized amount to
    // the remaining sell amount (`totalSellAmount - soldAmount`).
    function _normalizeSellAmount(
        uint256 rawAmount,
        uint256 totalSellAmount,
        uint256 soldAmount
    ) private pure returns (uint256 normalized) {
        if ((rawAmount & HIGH_BIT) == HIGH_BIT) {
            // If the high bit of `rawAmount` is set then the lower 255 bits
            // specify a fraction of `totalSellAmount`.
            return
                LibSafeMathV06.min256(
                    (totalSellAmount * LibSafeMathV06.min256(rawAmount & LOWER_255_BITS, 1e18)) / 1e18,
                    totalSellAmount.safeSub(soldAmount)
                );
        } else {
            return LibSafeMathV06.min256(rawAmount, totalSellAmount.safeSub(soldAmount));
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2023 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity >=0.6.5 <0.9;

interface IERC20Token {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /// @dev `msg.sender` approves `spender` to spend `value` tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @param value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address spender, uint256 value) external returns (bool);

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply() external view returns (uint256);

    /// @dev Get the balance of `owner`.
    /// @param owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address owner) external view returns (uint256);

    /// @dev Get the allowance for `spender` to spend from `owner`.
    /// @param owner The address of the account owning tokens
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address owner, address spender) external view returns (uint256);

    /// @dev Get the number of decimals this token has.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./IERC20Token.sol";

interface IEtherToken is IERC20Token {
    /// @dev Wrap ether.
    function deposit() external payable;

    /// @dev Unwrap ether.
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./errors/LibRichErrorsV06.sol";
import "./errors/LibSafeMathRichErrorsV06.sol";

library LibSafeMathV06 {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.DIVISION_BY_ZERO,
                    a,
                    b
                )
            );
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                    a,
                    b
                )
            );
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.ADDITION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function safeMul128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (a == 0) {
            return 0;
        }
        uint128 c = a * b;
        if (c / a != b) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function safeDiv128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (b == 0) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.DIVISION_BY_ZERO,
                    a,
                    b
                )
            );
        }
        uint128 c = a / b;
        return c;
    }

    function safeSub128(uint128 a, uint128 b) internal pure returns (uint128) {
        if (b > a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                    a,
                    b
                )
            );
        }
        return a - b;
    }

    function safeAdd128(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        if (c < a) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256BinOpError(
                    LibSafeMathRichErrorsV06.BinOpErrorCodes.ADDITION_OVERFLOW,
                    a,
                    b
                )
            );
        }
        return c;
    }

    function max128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a >= b ? a : b;
    }

    function min128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }

    function safeDowncastToUint128(uint256 a) internal pure returns (uint128) {
        if (a > type(uint128).max) {
            LibRichErrorsV06.rrevert(
                LibSafeMathRichErrorsV06.Uint256DowncastError(
                    LibSafeMathRichErrorsV06.DowncastErrorCodes.VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT128,
                    a
                )
            );
        }
        return uint128(a);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibRichErrorsV06 {
    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR = 0x08c379a0;

    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(string memory message) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(STANDARD_ERROR_SELECTOR, bytes(message));
    }

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData) internal pure {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibSafeMathRichErrorsV06 {
    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR = 0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR = 0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT128
    }

    function Uint256BinOpError(BinOpErrorCodes errorCode, uint256 a, uint256 b) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(UINT256_BINOP_ERROR_SELECTOR, errorCode, a, b);
    }

    function Uint256DowncastError(DowncastErrorCodes errorCode, uint256 a) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(UINT256_DOWNCAST_ERROR_SELECTOR, errorCode, a);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/src/IERC20Token.sol";
import "../vendor/ILiquidityProvider.sol";

interface ILiquidityProviderSandbox {
    /// @dev Calls `sellTokenForToken` on the given `provider` contract to
    ///      trigger a trade.
    /// @param provider The address of the on-chain liquidity provider.
    /// @param inputToken The token being sold.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    function executeSellTokenForToken(
        ILiquidityProvider provider,
        IERC20Token inputToken,
        IERC20Token outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external;

    /// @dev Calls `sellEthForToken` on the given `provider` contract to
    ///      trigger a trade.
    /// @param provider The address of the on-chain liquidity provider.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    function executeSellEthForToken(
        ILiquidityProvider provider,
        IERC20Token outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external;

    /// @dev Calls `sellTokenForEth` on the given `provider` contract to
    ///      trigger a trade.
    /// @param provider The address of the on-chain liquidity provider.
    /// @param inputToken The token being sold.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of ETH to buy.
    /// @param auxiliaryData Auxiliary data supplied to the `provider` contract.
    function executeSellTokenForEth(
        ILiquidityProvider provider,
        IERC20Token inputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

import "@0x/contracts-erc20/src/IERC20Token.sol";

interface ILiquidityProvider {
    /// @dev An optional event an LP can emit for each fill against a source.
    /// @param inputToken The input token.
    /// @param outputToken The output token.
    /// @param inputTokenAmount How much input token was sold.
    /// @param outputTokenAmount How much output token was bought.
    /// @param sourceId A bytes32 encoded ascii source ID. E.g., `bytes32('Curve')`/
    /// @param sourceAddress An optional address associated with the source (e.g, a curve pool).
    /// @param sourceId A bytes32 encoded ascii source ID. E.g., `bytes32('Curve')`/
    /// @param sourceAddress An optional address associated with the source (e.g, a curve pool).
    /// @param sender The caller of the LP.
    /// @param recipient The recipient of the output tokens.
    event LiquidityProviderFill(
        IERC20Token inputToken,
        IERC20Token outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount,
        bytes32 sourceId,
        address sourceAddress,
        address sender,
        address recipient
    );

    /// @dev Trades `inputToken` for `outputToken`. The amount of `inputToken`
    ///      to sell must be transferred to the contract prior to calling this
    ///      function to trigger the trade.
    /// @param inputToken The token being sold.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of `outputToken` bought.
    function sellTokenForToken(
        IERC20Token inputToken,
        IERC20Token outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external returns (uint256 boughtAmount);

    /// @dev Trades ETH for token. ETH must either be attached to this function
    ///      call or sent to the contract prior to calling this function to
    ///      trigger the trade.
    /// @param outputToken The token being bought.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of `outputToken` to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of `outputToken` bought.
    function sellEthForToken(
        IERC20Token outputToken,
        address recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external payable returns (uint256 boughtAmount);

    /// @dev Trades token for ETH. The token must be sent to the contract prior
    ///      to calling this function to trigger the trade.
    /// @param inputToken The token being sold.
    /// @param recipient The recipient of the bought tokens.
    /// @param minBuyAmount The minimum acceptable amount of ETH to buy.
    /// @param auxiliaryData Arbitrary auxiliary data supplied to the contract.
    /// @return boughtAmount The amount of ETH bought.
    function sellTokenForEth(
        IERC20Token inputToken,
        address payable recipient,
        uint256 minBuyAmount,
        bytes calldata auxiliaryData
    ) external returns (uint256 boughtAmount);

    /// @dev Quotes the amount of `outputToken` that would be obtained by
    ///      selling `sellAmount` of `inputToken`.
    /// @param inputToken Address of the taker token (what to sell). Use
    ///        the wETH address if selling ETH.
    /// @param outputToken Address of the maker token (what to buy). Use
    ///        the wETH address if buying ETH.
    /// @param sellAmount Amount of `inputToken` to sell.
    /// @return outputTokenAmount Amount of `outputToken` that would be obtained.
    function getSellQuote(
        IERC20Token inputToken,
        IERC20Token outputToken,
        uint256 sellAmount
    ) external view returns (uint256 outputTokenAmount);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibCommonRichErrors.sol";
import "../errors/LibOwnableRichErrors.sol";
import "../features/interfaces/IOwnableFeature.sol";
import "../features/interfaces/ISimpleFunctionRegistryFeature.sol";

/// @dev Common feature utilities.
abstract contract FixinCommon {
    using LibRichErrorsV06 for bytes;

    /// @dev The implementation address of this feature.
    address internal immutable _implementation;

    /// @dev The caller must be this contract.
    modifier onlySelf() virtual {
        if (msg.sender != address(this)) {
            LibCommonRichErrors.OnlyCallableBySelfError(msg.sender).rrevert();
        }
        _;
    }

    /// @dev The caller of this function must be the owner.
    modifier onlyOwner() virtual {
        {
            address owner = IOwnableFeature(address(this)).owner();
            if (msg.sender != owner) {
                LibOwnableRichErrors.OnlyOwnerError(msg.sender, owner).rrevert();
            }
        }
        _;
    }

    constructor() internal {
        // Remember this feature's original address.
        _implementation = address(this);
    }

    /// @dev Registers a function implemented by this feature at `_implementation`.
    ///      Can and should only be called within a `migrate()`.
    /// @param selector The selector of the function whose implementation
    ///        is at `_implementation`.
    function _registerFeatureFunction(bytes4 selector) internal {
        ISimpleFunctionRegistryFeature(address(this)).extend(selector, _implementation);
    }

    /// @dev Encode a feature version as a `uint256`.
    /// @param major The major version number of the feature.
    /// @param minor The minor version number of the feature.
    /// @param revision The revision number of the feature.
    /// @return encodedVersion The encoded version number.
    function _encodeVersion(
        uint32 major,
        uint32 minor,
        uint32 revision
    ) internal pure returns (uint256 encodedVersion) {
        return (uint256(major) << 64) | (uint256(minor) << 32) | uint256(revision);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibCommonRichErrors {
    function OnlyCallableBySelfError(address sender) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("OnlyCallableBySelfError(address)")), sender);
    }

    function IllegalReentrancyError(bytes4 selector, uint256 reentrancyFlags) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("IllegalReentrancyError(bytes4,uint256)")),
                selector,
                reentrancyFlags
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibOwnableRichErrors {
    function OnlyOwnerError(address sender, address owner) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("OnlyOwnerError(address,address)")), sender, owner);
    }

    function TransferOwnerToZeroError() internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("TransferOwnerToZeroError()")));
    }

    function MigrateCallFailedError(address target, bytes memory resultData) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("MigrateCallFailedError(address,bytes)")), target, resultData);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/interfaces/IOwnableV06.sol";

/// @dev Owner management and migration features.
interface IOwnableFeature is IOwnableV06 {
    /// @dev Emitted when `migrate()` is called.
    /// @param caller The caller of `migrate()`.
    /// @param migrator The migration contract.
    /// @param newOwner The address of the new owner.
    event Migrated(address caller, address migrator, address newOwner);

    /// @dev Execute a migration function in the context of the ZeroEx contract.
    ///      The result of the function being called should be the magic bytes
    ///      0x2c64c5ef (`keccack('MIGRATE_SUCCESS')`). Only callable by the owner.
    ///      The owner will be temporarily set to `address(this)` inside the call.
    ///      Before returning, the owner will be set to `newOwner`.
    /// @param target The migrator contract address.
    /// @param newOwner The address of the new owner.
    /// @param data The call data.
    function migrate(address target, bytes calldata data, address newOwner) external;
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

interface IOwnableV06 {
    /// @dev Emitted by Ownable when ownership is transferred.
    /// @param previousOwner The previous owner of the contract.
    /// @param newOwner The new owner of the contract.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Transfers ownership of the contract to a new address.
    /// @param newOwner The address that will become the owner.
    function transferOwnership(address newOwner) external;

    /// @dev The owner of this contract.
    /// @return ownerAddress The owner address.
    function owner() external view returns (address ownerAddress);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

/// @dev Basic registry management features.
interface ISimpleFunctionRegistryFeature {
    /// @dev A function implementation was updated via `extend()` or `rollback()`.
    /// @param selector The function selector.
    /// @param oldImpl The implementation contract address being replaced.
    /// @param newImpl The replacement implementation contract address.
    event ProxyFunctionUpdated(bytes4 indexed selector, address oldImpl, address newImpl);

    /// @dev Roll back to a prior implementation of a function.
    /// @param selector The function selector.
    /// @param targetImpl The address of an older implementation of the function.
    function rollback(bytes4 selector, address targetImpl) external;

    /// @dev Register or replace a function.
    /// @param selector The function selector.
    /// @param impl The implementation contract for the function.
    function extend(bytes4 selector, address impl) external;

    /// @dev Retrieve the length of the rollback history for a function.
    /// @param selector The function selector.
    /// @return rollbackLength The number of items in the rollback history for
    ///         the function.
    function getRollbackLength(bytes4 selector) external view returns (uint256 rollbackLength);

    /// @dev Retrieve an entry in the rollback history for a function.
    /// @param selector The function selector.
    /// @param idx The index in the rollback history.
    /// @return impl An implementation address for the function at
    ///         index `idx`.
    function getRollbackEntryAtIndex(bytes4 selector, uint256 idx) external view returns (address impl);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibCommonRichErrors.sol";
import "../errors/LibOwnableRichErrors.sol";

/// @dev EIP712 helpers for features.
abstract contract FixinEIP712 {
    /// @dev The domain hash separator for the entire exchange proxy.
    bytes32 public immutable EIP712_DOMAIN_SEPARATOR;

    constructor(address zeroExAddress) internal {
        // Compute `EIP712_DOMAIN_SEPARATOR`
        {
            uint256 chainId;
            assembly {
                chainId := chainid()
            }
            EIP712_DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain("
                        "string name,"
                        "string version,"
                        "uint256 chainId,"
                        "address verifyingContract"
                        ")"
                    ),
                    keccak256("ZeroEx"),
                    keccak256("1.0.0"),
                    chainId,
                    zeroExAddress
                )
            );
        }
    }

    function _getEIP712Hash(bytes32 structHash) internal view returns (bytes32 eip712Hash) {
        return keccak256(abi.encodePacked(hex"1901", EIP712_DOMAIN_SEPARATOR, structHash));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../errors/LibOwnableRichErrors.sol";

library LibMigrate {
    /// @dev Magic bytes returned by a migrator to indicate success.
    ///      This is `keccack('MIGRATE_SUCCESS')`.
    bytes4 internal constant MIGRATE_SUCCESS = 0x2c64c5ef;

    using LibRichErrorsV06 for bytes;

    /// @dev Perform a delegatecall and ensure it returns the magic bytes.
    /// @param target The call target.
    /// @param data The call data.
    function delegatecallMigrateFunction(address target, bytes memory data) internal {
        (bool success, bytes memory resultData) = target.delegatecall(data);
        if (!success || resultData.length != 32 || abi.decode(resultData, (bytes4)) != MIGRATE_SUCCESS) {
            LibOwnableRichErrors.MigrateCallFailedError(target, resultData).rrevert();
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

/// @dev Basic interface for a feature contract.
interface IFeature {
    /// @dev The name of this feature set.
    function FEATURE_NAME() external view returns (string memory name);

    /// @dev The version of this feature set.
    function FEATURE_VERSION() external view returns (uint256 version);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/src/IERC20Token.sol";

interface IMultiplexFeature {
    // Identifies the type of subcall.
    enum MultiplexSubcall {
        Invalid,
        RFQ,
        OTC,
        UniswapV2,
        UniswapV3,
        LiquidityProvider,
        TransformERC20,
        BatchSell,
        MultiHopSell
    }

    // Parameters for a batch sell.
    struct BatchSellParams {
        // The token being sold.
        IERC20Token inputToken;
        // The token being bought.
        IERC20Token outputToken;
        // The amount of `inputToken` to sell.
        uint256 sellAmount;
        // The nested calls to perform.
        BatchSellSubcall[] calls;
        // Whether to use the Exchange Proxy's balance
        // of input tokens.
        bool useSelfBalance;
        // The recipient of the bought output tokens.
        address recipient;
        // The sender of the input tokens.
        address payer;
    }

    // Represents a constituent call of a batch sell.
    struct BatchSellSubcall {
        // The function to call.
        MultiplexSubcall id;
        // Amount of input token to sell. If the highest bit is 1,
        // this value represents a proportion of the total
        // `sellAmount` of the batch sell. See `_normalizeSellAmount`
        // for details.
        uint256 sellAmount;
        // ABI-encoded parameters needed to perform the call.
        bytes data;
    }

    // Parameters for a multi-hop sell.
    struct MultiHopSellParams {
        // The sell path, i.e.
        // tokens = [inputToken, hopToken1, ..., hopTokenN, outputToken]
        address[] tokens;
        // The amount of `tokens[0]` to sell.
        uint256 sellAmount;
        // The nested calls to perform.
        MultiHopSellSubcall[] calls;
        // Whether to use the Exchange Proxy's balance
        // of input tokens.
        bool useSelfBalance;
        // The recipient of the bought output tokens.
        address recipient;
        // The sender of the input tokens.
        address payer;
    }

    // Represents a constituent call of a multi-hop sell.
    struct MultiHopSellSubcall {
        // The function to call.
        MultiplexSubcall id;
        // ABI-encoded parameters needed to perform the call.
        bytes data;
    }

    struct BatchSellState {
        // Tracks the amount of input token sold.
        uint256 soldAmount;
        // Tracks the amount of output token bought.
        uint256 boughtAmount;
    }

    struct MultiHopSellState {
        // This variable is used for the input and output amounts of
        // each hop. After the final hop, this will contain the output
        // amount of the multi-hop sell.
        uint256 outputTokenAmount;
        // For each hop in a multi-hop sell, `from` is the
        // address that holds the input tokens of the hop,
        // `to` is the address that receives the output tokens
        // of the hop.
        // See `_computeHopTarget` for details.
        address from;
        address to;
        // The index of the current hop in the multi-hop chain.
        uint256 hopIndex;
    }

    /// @dev Sells attached ETH for `outputToken` using the provided
    ///      calls.
    /// @param outputToken The token to buy.
    /// @param calls The calls to use to sell the attached ETH.
    /// @param minBuyAmount The minimum amount of `outputToken` that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function multiplexBatchSellEthForToken(
        IERC20Token outputToken,
        BatchSellSubcall[] calldata calls,
        uint256 minBuyAmount
    ) external payable returns (uint256 boughtAmount);

    /// @dev Sells `sellAmount` of the given `inputToken` for ETH
    ///      using the provided calls.
    /// @param inputToken The token to sell.
    /// @param calls The calls to use to sell the input tokens.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of ETH that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of ETH bought.
    function multiplexBatchSellTokenForEth(
        IERC20Token inputToken,
        BatchSellSubcall[] calldata calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) external returns (uint256 boughtAmount);

    /// @dev Sells `sellAmount` of the given `inputToken` for
    ///      `outputToken` using the provided calls.
    /// @param inputToken The token to sell.
    /// @param outputToken The token to buy.
    /// @param calls The calls to use to sell the input tokens.
    /// @param sellAmount The amount of `inputToken` to sell.
    /// @param minBuyAmount The minimum amount of `outputToken`
    ///        that must be bought for this function to not revert.
    /// @return boughtAmount The amount of `outputToken` bought.
    function multiplexBatchSellTokenForToken(
        IERC20Token inputToken,
        IERC20Token outputToken,
        BatchSellSubcall[] calldata calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) external returns (uint256 boughtAmount);

    /// @dev Executes a multiplex BatchSell using the given
    ///      parameters. Internal only.
    /// @param params The parameters for the BatchSell.
    /// @param minBuyAmount The minimum amount of `params.outputToken`
    ///        that must be bought for this function to not revert.
    /// @return boughtAmount The amount of `params.outputToken` bought.
    function _multiplexBatchSell(
        BatchSellParams memory params,
        uint256 minBuyAmount
    ) external returns (uint256 boughtAmount);

    /// @dev Sells attached ETH via the given sequence of tokens
    ///      and calls. `tokens[0]` must be WETH.
    ///      The last token in `tokens` is the output token that
    ///      will ultimately be sent to `msg.sender`
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function multiplexMultiHopSellEthForToken(
        address[] calldata tokens,
        MultiHopSellSubcall[] calldata calls,
        uint256 minBuyAmount
    ) external payable returns (uint256 boughtAmount);

    /// @dev Sells `sellAmount` of the input token (`tokens[0]`)
    ///      for ETH via the given sequence of tokens and calls.
    ///      The last token in `tokens` must be WETH.
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param minBuyAmount The minimum amount of ETH that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of ETH bought.
    function multiplexMultiHopSellTokenForEth(
        address[] calldata tokens,
        MultiHopSellSubcall[] calldata calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) external returns (uint256 boughtAmount);

    /// @dev Sells `sellAmount` of the input token (`tokens[0]`)
    ///      via the given sequence of tokens and calls.
    ///      The last token in `tokens` is the output token that
    ///      will ultimately be sent to `msg.sender`
    /// @param tokens The sequence of tokens to use for the sell,
    ///        i.e. `tokens[i]` will be sold for `tokens[i+1]` via
    ///        `calls[i]`.
    /// @param calls The sequence of calls to use for the sell.
    /// @param minBuyAmount The minimum amount of output tokens that
    ///        must be bought for this function to not revert.
    /// @return boughtAmount The amount of output tokens bought.
    function multiplexMultiHopSellTokenForToken(
        address[] calldata tokens,
        MultiHopSellSubcall[] calldata calls,
        uint256 sellAmount,
        uint256 minBuyAmount
    ) external returns (uint256 boughtAmount);

    /// @dev Executes a multiplex MultiHopSell using the given
    ///      parameters. Internal only.
    /// @param params The parameters for the MultiHopSell.
    /// @param minBuyAmount The minimum amount of the output token
    ///        that must be bought for this function to not revert.
    /// @return boughtAmount The amount of the output token bought.
    function _multiplexMultiHopSell(
        MultiHopSellParams memory params,
        uint256 minBuyAmount
    ) external returns (uint256 boughtAmount);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/src/IERC20Token.sol";
import "@0x/contracts-erc20/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../external/ILiquidityProviderSandbox.sol";
import "../../fixins/FixinCommon.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../../vendor/ILiquidityProvider.sol";
import "../interfaces/IMultiplexFeature.sol";

abstract contract MultiplexLiquidityProvider is FixinCommon, FixinTokenSpender {
    using LibERC20TokenV06 for IERC20Token;
    using LibSafeMathV06 for uint256;

    // Same event fired by LiquidityProviderFeature
    event LiquidityProviderSwap(
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount,
        address provider,
        address recipient
    );

    /// @dev The sandbox contract address.
    ILiquidityProviderSandbox private immutable SANDBOX;

    constructor(ILiquidityProviderSandbox sandbox) internal {
        SANDBOX = sandbox;
    }

    // A payable external function that we can delegatecall to
    // swallow reverts and roll back the input token transfer.
    function _batchSellLiquidityProviderExternal(
        IMultiplexFeature.BatchSellParams calldata params,
        bytes calldata wrappedCallData,
        uint256 sellAmount
    ) external payable returns (uint256 boughtAmount) {
        // Revert if not a delegatecall.
        require(
            address(this) != _implementation,
            "MultiplexLiquidityProvider::_batchSellLiquidityProviderExternal/ONLY_DELEGATECALL"
        );

        // Decode the provider address and auxiliary data.
        (address provider, bytes memory auxiliaryData) = abi.decode(wrappedCallData, (address, bytes));

        if (params.useSelfBalance) {
            // If `useSelfBalance` is true, use the input tokens
            // held by `address(this)`.
            _transferERC20Tokens(params.inputToken, provider, sellAmount);
        } else {
            // Otherwise, transfer the input tokens from `msg.sender`.
            _transferERC20TokensFrom(params.inputToken, params.payer, provider, sellAmount);
        }
        // Cache the recipient's balance of the output token.
        uint256 balanceBefore = params.outputToken.balanceOf(params.recipient);
        // Execute the swap.
        SANDBOX.executeSellTokenForToken(
            ILiquidityProvider(provider),
            params.inputToken,
            params.outputToken,
            params.recipient,
            0,
            auxiliaryData
        );
        // Compute amount of output token received by the
        // recipient.
        boughtAmount = params.outputToken.balanceOf(params.recipient).safeSub(balanceBefore);

        emit LiquidityProviderSwap(
            address(params.inputToken),
            address(params.outputToken),
            sellAmount,
            boughtAmount,
            provider,
            params.recipient
        );
    }

    function _batchSellLiquidityProvider(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        // Swallow reverts
        (bool success, bytes memory resultData) = _implementation.delegatecall(
            abi.encodeWithSelector(
                this._batchSellLiquidityProviderExternal.selector,
                params,
                wrappedCallData,
                sellAmount
            )
        );
        if (success) {
            // Decode the output token amount on success.
            uint256 boughtAmount = abi.decode(resultData, (uint256));
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(sellAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(boughtAmount);
        }
    }

    // This function is called after tokens have already been transferred
    // into the liquidity provider contract (in the previous hop).
    function _multiHopSellLiquidityProvider(
        IMultiplexFeature.MultiHopSellState memory state,
        IMultiplexFeature.MultiHopSellParams memory params,
        bytes memory wrappedCallData
    ) internal {
        IERC20Token inputToken = IERC20Token(params.tokens[state.hopIndex]);
        IERC20Token outputToken = IERC20Token(params.tokens[state.hopIndex + 1]);
        // Decode the provider address and auxiliary data.
        (address provider, bytes memory auxiliaryData) = abi.decode(wrappedCallData, (address, bytes));
        // Cache the recipient's balance of the output token.
        uint256 balanceBefore = outputToken.balanceOf(state.to);
        // Execute the swap.
        SANDBOX.executeSellTokenForToken(
            ILiquidityProvider(provider),
            inputToken,
            outputToken,
            state.to,
            0,
            auxiliaryData
        );
        // The previous `ouputTokenAmount` was effectively the
        // input amount for this call. Cache the value before
        // overwriting it with the new output token amount so
        // that both the input and ouput amounts can be in the
        // `LiquidityProviderSwap` event.
        uint256 sellAmount = state.outputTokenAmount;
        // Compute amount of output token received by the
        // recipient.
        state.outputTokenAmount = outputToken.balanceOf(state.to).safeSub(balanceBefore);

        emit LiquidityProviderSwap(
            address(inputToken),
            address(outputToken),
            sellAmount,
            state.outputTokenAmount,
            provider,
            state.to
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibBytesV06.sol";
import "../IERC20Token.sol";

library LibERC20TokenV06 {
    bytes private constant DECIMALS_CALL_DATA = hex"313ce567";

    /// @dev Calls `IERC20Token(token).approve()`.
    ///      Reverts if the return data is invalid or the call reverts.
    /// @param token The address of the token contract.
    /// @param spender The address that receives an allowance.
    /// @param allowance The allowance to set.
    function compatApprove(IERC20Token token, address spender, uint256 allowance) internal {
        bytes memory callData = abi.encodeWithSelector(token.approve.selector, spender, allowance);
        _callWithOptionalBooleanResult(address(token), callData);
    }

    /// @dev Calls `IERC20Token(token).approve()` and sets the allowance to the
    ///      maximum if the current approval is not already >= an amount.
    ///      Reverts if the return data is invalid or the call reverts.
    /// @param token The address of the token contract.
    /// @param spender The address that receives an allowance.
    /// @param amount The minimum allowance needed.
    function approveIfBelow(IERC20Token token, address spender, uint256 amount) internal {
        if (token.allowance(address(this), spender) < amount) {
            compatApprove(token, spender, uint256(-1));
        }
    }

    /// @dev Calls `IERC20Token(token).transfer()`.
    ///      Reverts if the return data is invalid or the call reverts.
    /// @param token The address of the token contract.
    /// @param to The address that receives the tokens
    /// @param amount Number of tokens to transfer.
    function compatTransfer(IERC20Token token, address to, uint256 amount) internal {
        bytes memory callData = abi.encodeWithSelector(token.transfer.selector, to, amount);
        _callWithOptionalBooleanResult(address(token), callData);
    }

    /// @dev Calls `IERC20Token(token).transferFrom()`.
    ///      Reverts if the return data is invalid or the call reverts.
    /// @param token The address of the token contract.
    /// @param from The owner of the tokens.
    /// @param to The address that receives the tokens
    /// @param amount Number of tokens to transfer.
    function compatTransferFrom(IERC20Token token, address from, address to, uint256 amount) internal {
        bytes memory callData = abi.encodeWithSelector(token.transferFrom.selector, from, to, amount);
        _callWithOptionalBooleanResult(address(token), callData);
    }

    /// @dev Retrieves the number of decimals for a token.
    ///      Returns `18` if the call reverts.
    /// @param token The address of the token contract.
    /// @return tokenDecimals The number of decimals places for the token.
    function compatDecimals(IERC20Token token) internal view returns (uint8 tokenDecimals) {
        tokenDecimals = 18;
        (bool didSucceed, bytes memory resultData) = address(token).staticcall(DECIMALS_CALL_DATA);
        if (didSucceed && resultData.length >= 32) {
            tokenDecimals = uint8(LibBytesV06.readUint256(resultData, 0));
        }
    }

    /// @dev Retrieves the allowance for a token, owner, and spender.
    ///      Returns `0` if the call reverts.
    /// @param token The address of the token contract.
    /// @param owner The owner of the tokens.
    /// @param spender The address the spender.
    /// @return allowance_ The allowance for a token, owner, and spender.
    function compatAllowance(
        IERC20Token token,
        address owner,
        address spender
    ) internal view returns (uint256 allowance_) {
        (bool didSucceed, bytes memory resultData) = address(token).staticcall(
            abi.encodeWithSelector(token.allowance.selector, owner, spender)
        );
        if (didSucceed && resultData.length >= 32) {
            allowance_ = LibBytesV06.readUint256(resultData, 0);
        }
    }

    /// @dev Retrieves the balance for a token owner.
    ///      Returns `0` if the call reverts.
    /// @param token The address of the token contract.
    /// @param owner The owner of the tokens.
    /// @return balance The token balance of an owner.
    function compatBalanceOf(IERC20Token token, address owner) internal view returns (uint256 balance) {
        (bool didSucceed, bytes memory resultData) = address(token).staticcall(
            abi.encodeWithSelector(token.balanceOf.selector, owner)
        );
        if (didSucceed && resultData.length >= 32) {
            balance = LibBytesV06.readUint256(resultData, 0);
        }
    }

    /// @dev Executes a call on address `target` with calldata `callData`
    ///      and asserts that either nothing was returned or a single boolean
    ///      was returned equal to `true`.
    /// @param target The call target.
    /// @param callData The abi-encoded call data.
    function _callWithOptionalBooleanResult(address target, bytes memory callData) private {
        (bool didSucceed, bytes memory resultData) = target.call(callData);
        // Revert if the call reverted.
        if (!didSucceed) {
            LibRichErrorsV06.rrevert(resultData);
        }
        // If we get back 0 returndata, this may be a non-standard ERC-20 that
        // does not return a boolean. Check that it at least contains code.
        if (resultData.length == 0) {
            uint256 size;
            assembly {
                size := extcodesize(target)
            }
            require(size > 0, "invalid token address, contains no code");
            return;
        }
        // If we get back at least 32 bytes, we know the target address
        // contains code, and we assume it is a token that returned a boolean
        // success value, which must be true.
        if (resultData.length >= 32) {
            uint256 result = LibBytesV06.readUint256(resultData, 0);
            if (result == 1) {
                return;
            } else {
                LibRichErrorsV06.rrevert(resultData);
            }
        }
        // If 0 < returndatasize < 32, the target is a contract, but not a
        // valid token.
        LibRichErrorsV06.rrevert(resultData);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "./errors/LibBytesRichErrorsV06.sol";
import "./errors/LibRichErrorsV06.sol";

library LibBytesV06 {
    using LibBytesV06 for bytes;

    /// @dev Gets the memory address for a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of byte array. This
    ///         points to the header of the byte array which contains
    ///         the length.
    function rawAddress(bytes memory input) internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }

    /// @dev Gets the memory address for the contents of a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of the contents of the byte array.
    function contentAddress(bytes memory input) internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

    /// @dev Copies `length` bytes from memory location `source` to `dest`.
    /// @param dest memory address to copy bytes to.
    /// @param source memory address to copy bytes from.
    /// @param length number of bytes to copy.
    function memCopy(uint256 dest, uint256 source, uint256 length) internal pure {
        if (length < 32) {
            // Handle a partial word by reading destination and masking
            // off the bits we are interested in.
            // This correctly handles overlap, zero lengths and source == dest
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
            // Skip the O(length) loop when source == dest.
            if (source == dest) {
                return;
            }

            // For large copies we copy whole words at a time. The final
            // word is aligned to the end of the range (instead of after the
            // previous) to handle partial words. So a copy will look like this:
            //
            //  ####
            //      ####
            //          ####
            //            ####
            //
            // We handle overlap in the source and destination range by
            // changing the copying direction. This prevents us from
            // overwriting parts of source that we still need to copy.
            //
            // This correctly handles source == dest
            //
            if (source > dest) {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because it
                    // is easier to compare with in the loop, and these
                    // are also the addresses we need for copying the
                    // last bytes.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the last 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the last bytes in
                    // source already due to overlap.
                    let last := mload(sEnd)

                    // Copy whole words front to back
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    for {

                    } lt(source, sEnd) {

                    } {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                    // Write the last 32 bytes
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because those
                    // are the starting points when copying a word at the end.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the first 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the first bytes in
                    // source already due to overlap.
                    let first := mload(source)

                    // Copy whole words back to front
                    // We use a signed comparisson here to allow dEnd to become
                    // negative (happens when source and dest < 32). Valid
                    // addresses in local memory will never be larger than
                    // 2**255, so they can be safely re-interpreted as signed.
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    for {

                    } slt(dest, dEnd) {

                    } {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                    // Write the first 32 bytes
                    mstore(dest, first)
                }
            }
        }
    }

    /// @dev Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function slice(bytes memory b, uint256 from, uint256 to) internal pure returns (bytes memory result) {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                    from,
                    to
                )
            );
        }
        if (to > b.length) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                    to,
                    b.length
                )
            );
        }

        // Create a new bytes structure and copy contents
        result = new bytes(to - from);
        memCopy(result.contentAddress(), b.contentAddress() + from, result.length);
        return result;
    }

    /// @dev Returns a slice from a byte array without preserving the input.
    ///      When `from == 0`, the original array will match the slice.
    ///      In other cases its state will be corrupted.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function sliceDestructive(bytes memory b, uint256 from, uint256 to) internal pure returns (bytes memory result) {
        // Ensure that the from and to positions are valid positions for a slice within
        // the byte array that is being used.
        if (from > to) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.FromLessThanOrEqualsToRequired,
                    from,
                    to
                )
            );
        }
        if (to > b.length) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.ToLessThanOrEqualsLengthRequired,
                    to,
                    b.length
                )
            );
        }

        // Create a new bytes structure around [from, to) in-place.
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

    /// @dev Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return result The byte that was popped off.
    function popLastByte(bytes memory b) internal pure returns (bytes1 result) {
        if (b.length == 0) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanZeroRequired,
                    b.length,
                    0
                )
            );
        }

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return equal True if arrays are the same. False otherwise.
    function equals(bytes memory lhs, bytes memory rhs) internal pure returns (bool equal) {
        // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
        // We early exit on unequal lengths, but keccak would also correctly
        // handle this.
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(bytes memory b, uint256 index) internal pure returns (address result) {
        if (b.length < index + 20) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                    b.length,
                    index + 20 // 20 is length of address
                )
            );
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /// @dev Writes an address into a specific position in a byte array.
    /// @param b Byte array to insert address into.
    /// @param index Index in byte array of address.
    /// @param input Address to put into byte array.
    function writeAddress(bytes memory b, uint256 index, address input) internal pure {
        if (b.length < index + 20) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsTwentyRequired,
                    b.length,
                    index + 20 // 20 is length of address
                )
            );
        }

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Store address into array memory
        assembly {
            // The address occupies 20 bytes and mstore stores 32 bytes.
            // First fetch the 32-byte word where we'll be storing the address, then
            // apply a mask so we have only the bytes in the word that the address will not occupy.
            // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )

            // Make sure input address is clean.
            // (Solidity does not guarantee this)
            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

            // Store the neighbors and address into memory
            mstore(add(b, index), xor(input, neighbors))
        }
    }

    /// @dev Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return result bytes32 value from byte array.
    function readBytes32(bytes memory b, uint256 index) internal pure returns (bytes32 result) {
        if (b.length < index + 32) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                    b.length,
                    index + 32
                )
            );
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Writes a bytes32 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes32 to put into byte array.
    function writeBytes32(bytes memory b, uint256 index, bytes32 input) internal pure {
        if (b.length < index + 32) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsThirtyTwoRequired,
                    b.length,
                    index + 32
                )
            );
        }

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(b, index), input)
        }
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(bytes memory b, uint256 index) internal pure returns (uint256 result) {
        result = uint256(readBytes32(b, index));
        return result;
    }

    /// @dev Writes a uint256 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input uint256 to put into byte array.
    function writeUint256(bytes memory b, uint256 index, uint256 input) internal pure {
        writeBytes32(b, index, bytes32(input));
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(bytes memory b, uint256 index) internal pure returns (bytes4 result) {
        if (b.length < index + 4) {
            LibRichErrorsV06.rrevert(
                LibBytesRichErrorsV06.InvalidByteOperationError(
                    LibBytesRichErrorsV06.InvalidByteOperationErrorCodes.LengthGreaterThanOrEqualsFourRequired,
                    b.length,
                    index + 4
                )
            );
        }

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    /// @dev Writes a new length to a byte array.
    ///      Decreasing length will lead to removing the corresponding lower order bytes from the byte array.
    ///      Increasing length may lead to appending adjacent in-memory bytes to the end of the byte array.
    /// @param b Bytes array to write new length to.
    /// @param length New length of byte array.
    function writeLength(bytes memory b, uint256 length) internal pure {
        assembly {
            mstore(b, length)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibBytesRichErrorsV06 {
    enum InvalidByteOperationErrorCodes {
        FromLessThanOrEqualsToRequired,
        ToLessThanOrEqualsLengthRequired,
        LengthGreaterThanZeroRequired,
        LengthGreaterThanOrEqualsFourRequired,
        LengthGreaterThanOrEqualsTwentyRequired,
        LengthGreaterThanOrEqualsThirtyTwoRequired,
        LengthGreaterThanOrEqualsNestedBytesLengthRequired,
        DestinationLengthGreaterThanOrEqualSourceLengthRequired
    }

    // bytes4(keccak256("InvalidByteOperationError(uint8,uint256,uint256)"))
    bytes4 internal constant INVALID_BYTE_OPERATION_ERROR_SELECTOR = 0x28006595;

    function InvalidByteOperationError(
        InvalidByteOperationErrorCodes errorCode,
        uint256 offset,
        uint256 required
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(INVALID_BYTE_OPERATION_ERROR_SELECTOR, errorCode, offset, required);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/src/IERC20Token.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";

/// @dev Helpers for moving tokens around.
abstract contract FixinTokenSpender {
    // Mask of the lower 20 bytes of a bytes32.
    uint256 private constant ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20TokensFrom(IERC20Token token, address owner, address to, uint256 amount) internal {
        require(address(token) != address(this), "FixinTokenSpender/CANNOT_INVOKE_SELF");

        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), amount)

            let success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success, // call itself succeeded
                or(
                    iszero(rdsize), // no return data, or
                    and(
                        iszero(lt(rdsize, 32)), // at least 32 bytes
                        eq(mload(ptr), 1) // starts with uint256(1)
                    )
                )
            )

            if iszero(success) {
                returndatacopy(ptr, 0, rdsize)
                revert(ptr, rdsize)
            }
        }
    }

    /// @dev Transfers ERC20 tokens from ourselves to `to`.
    /// @param token The token to spend.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20Tokens(IERC20Token token, address to, uint256 amount) internal {
        require(address(token) != address(this), "FixinTokenSpender/CANNOT_INVOKE_SELF");

        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transfer(address,uint256)
            mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x24), amount)

            let success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x44, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success, // call itself succeeded
                or(
                    iszero(rdsize), // no return data, or
                    and(
                        iszero(lt(rdsize, 32)), // at least 32 bytes
                        eq(mload(ptr), 1) // starts with uint256(1)
                    )
                )
            )

            if iszero(success) {
                returndatacopy(ptr, 0, rdsize)
                revert(ptr, rdsize)
            }
        }
    }

    /// @dev Transfers some amount of ETH to the given recipient and
    ///      reverts if the transfer fails.
    /// @param recipient The recipient of the ETH.
    /// @param amount The amount of ETH to transfer.
    function _transferEth(address payable recipient, uint256 amount) internal {
        if (amount > 0) {
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "FixinTokenSpender::_transferEth/TRANSFER_FAILED");
        }
    }

    /// @dev Gets the maximum amount of an ERC20 token `token` that can be
    ///      pulled from `owner` by this address.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @return amount The amount of tokens that can be pulled.
    function _getSpendableERC20BalanceOf(IERC20Token token, address owner) internal view returns (uint256) {
        return LibSafeMathV06.min256(token.allowance(owner, address(this)), token.balanceOf(owner));
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinEIP712.sol";
import "../interfaces/IMultiplexFeature.sol";
import "../interfaces/IOtcOrdersFeature.sol";
import "../libs/LibNativeOrder.sol";

abstract contract MultiplexOtc is FixinEIP712 {
    using LibSafeMathV06 for uint256;

    event ExpiredOtcOrder(bytes32 orderHash, address maker, uint64 expiry);

    function _batchSellOtcOrder(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        // Decode the Otc order and signature.
        (LibNativeOrder.OtcOrder memory order, LibSignature.Signature memory signature) = abi.decode(
            wrappedCallData,
            (LibNativeOrder.OtcOrder, LibSignature.Signature)
        );
        // Validate tokens.
        require(
            order.takerToken == params.inputToken && order.makerToken == params.outputToken,
            "MultiplexOtc::_batchSellOtcOrder/OTC_ORDER_INVALID_TOKENS"
        );
        // Pre-emptively check if the order is expired.
        uint64 expiry = uint64(order.expiryAndNonce >> 192);
        if (expiry <= uint64(block.timestamp)) {
            bytes32 orderHash = _getEIP712Hash(LibNativeOrder.getOtcOrderStructHash(order));
            emit ExpiredOtcOrder(orderHash, order.maker, expiry);
            return;
        }
        // Try filling the Otc order. Swallows reverts.
        try
            IOtcOrdersFeature(address(this))._fillOtcOrder(
                order,
                signature,
                sellAmount.safeDowncastToUint128(),
                params.payer,
                params.useSelfBalance,
                params.recipient
            )
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(takerTokenFilledAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(makerTokenFilledAmount);
        } catch {}
    }

    function _multiHopSellOtcOrder(
        IMultiplexFeature.MultiHopSellState memory state,
        IMultiplexFeature.MultiHopSellParams memory params,
        bytes memory wrappedCallData
    ) internal {
        // Decode the Otc order, and signature.
        (LibNativeOrder.OtcOrder memory order, LibSignature.Signature memory signature) = abi.decode(
            wrappedCallData,
            (LibNativeOrder.OtcOrder, LibSignature.Signature)
        );
        //Make sure that the otc orders maker and taker tokens match the fill sequence in params.tokens[]
        require(
            address(order.takerToken) == params.tokens[state.hopIndex] &&
                address(order.makerToken) == params.tokens[state.hopIndex + 1],
            "MultiplexOtcOrder::_multiHopSellOtcOrder/INVALID_TOKENS"
        );
        // Try filling the Otc order. Bubble up reverts.
        (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) = IOtcOrdersFeature(address(this))
            ._fillOtcOrder(
                order,
                signature,
                state.outputTokenAmount.safeDowncastToUint128(),
                state.from,
                params.useSelfBalance,
                state.to
            );
        //store the bought amount for the next hop
        state.outputTokenAmount = makerTokenFilledAmount;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "../libs/LibNativeOrder.sol";
import "../libs/LibSignature.sol";

/// @dev Feature for interacting with OTC orders.
interface IOtcOrdersFeature {
    /// @dev Emitted whenever an `OtcOrder` is filled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param makerTokenFilledAmount How much maker token was filled.
    /// @param takerTokenFilledAmount How much taker token was filled.
    event OtcOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address makerToken,
        address takerToken,
        uint128 makerTokenFilledAmount,
        uint128 takerTokenFilledAmount
    );

    /// @dev Fill an OTC order for up to `takerTokenFillAmount` taker tokens.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOtcOrder(
        LibNativeOrder.OtcOrder calldata order,
        LibSignature.Signature calldata makerSignature,
        uint128 takerTokenFillAmount
    ) external returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an OTC order for up to `takerTokenFillAmount` taker tokens.
    ///      Unwraps bought WETH into ETH before sending it to
    ///      the taker.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOtcOrderForEth(
        LibNativeOrder.OtcOrder calldata order,
        LibSignature.Signature calldata makerSignature,
        uint128 takerTokenFillAmount
    ) external returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an OTC order whose taker token is WETH for up
    ///      to `msg.value`.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOtcOrderWithEth(
        LibNativeOrder.OtcOrder calldata order,
        LibSignature.Signature calldata makerSignature
    ) external payable returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fully fill an OTC order. "Meta-transaction" variant,
    ///      requires order to be signed by both maker and taker.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerSignature The order signature from the taker.
    function fillTakerSignedOtcOrder(
        LibNativeOrder.OtcOrder calldata order,
        LibSignature.Signature calldata makerSignature,
        LibSignature.Signature calldata takerSignature
    ) external;

    /// @dev Fully fill an OTC order. "Meta-transaction" variant,
    ///      requires order to be signed by both maker and taker.
    ///      Unwraps bought WETH into ETH before sending it to
    ///      the taker.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerSignature The order signature from the taker.
    function fillTakerSignedOtcOrderForEth(
        LibNativeOrder.OtcOrder calldata order,
        LibSignature.Signature calldata makerSignature,
        LibSignature.Signature calldata takerSignature
    ) external;

    /// @dev Fills multiple taker-signed OTC orders.
    /// @param orders Array of OTC orders.
    /// @param makerSignatures Array of maker signatures for each order.
    /// @param takerSignatures Array of taker signatures for each order.
    /// @param unwrapWeth Array of booleans representing whether or not
    ///        to unwrap bought WETH into ETH for each order. Should be set
    ///        to false if the maker token is not WETH.
    /// @return successes Array of booleans representing whether or not
    ///         each order in `orders` was filled successfully.
    function batchFillTakerSignedOtcOrders(
        LibNativeOrder.OtcOrder[] calldata orders,
        LibSignature.Signature[] calldata makerSignatures,
        LibSignature.Signature[] calldata takerSignatures,
        bool[] calldata unwrapWeth
    ) external returns (bool[] memory successes);

    /// @dev Fill an OTC order for up to `takerTokenFillAmount` taker tokens.
    ///      Internal variant.
    /// @param order The OTC order.
    /// @param makerSignature The order signature from the maker.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this
    ///        order with.
    /// @param taker The address to fill the order in the context of.
    /// @param useSelfBalance Whether to use the Exchange Proxy's balance
    ///        of input tokens.
    /// @param recipient The recipient of the bought maker tokens.
    /// @return takerTokenFilledAmount How much taker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillOtcOrder(
        LibNativeOrder.OtcOrder calldata order,
        LibSignature.Signature calldata makerSignature,
        uint128 takerTokenFillAmount,
        address taker,
        bool useSelfBalance,
        address recipient
    ) external returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Get the order info for an OTC order.
    /// @param order The OTC order.
    /// @return orderInfo Info about the order.
    function getOtcOrderInfo(
        LibNativeOrder.OtcOrder calldata order
    ) external view returns (LibNativeOrder.OtcOrderInfo memory orderInfo);

    /// @dev Get the canonical hash of an OTC order.
    /// @param order The OTC order.
    /// @return orderHash The order hash.
    function getOtcOrderHash(LibNativeOrder.OtcOrder calldata order) external view returns (bytes32 orderHash);

    /// @dev Get the last nonce used for a particular
    ///      tx.origin address and nonce bucket.
    /// @param txOrigin The address.
    /// @param nonceBucket The nonce bucket index.
    /// @return lastNonce The last nonce value used.
    function lastOtcTxOriginNonce(address txOrigin, uint64 nonceBucket) external view returns (uint128 lastNonce);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/src/IERC20Token.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../errors/LibNativeOrdersRichErrors.sol";

/// @dev A library for common native order operations.
library LibNativeOrder {
    using LibSafeMathV06 for uint256;
    using LibRichErrorsV06 for bytes;

    enum OrderStatus {
        INVALID,
        FILLABLE,
        FILLED,
        CANCELLED,
        EXPIRED
    }

    /// @dev A standard OTC or OO limit order.
    struct LimitOrder {
        IERC20Token makerToken;
        IERC20Token takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        uint128 takerTokenFeeAmount;
        address maker;
        address taker;
        address sender;
        address feeRecipient;
        bytes32 pool;
        uint64 expiry;
        uint256 salt;
    }

    /// @dev An RFQ limit order.
    struct RfqOrder {
        IERC20Token makerToken;
        IERC20Token takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        address maker;
        address taker;
        address txOrigin;
        bytes32 pool;
        uint64 expiry;
        uint256 salt;
    }

    /// @dev An OTC limit order.
    struct OtcOrder {
        IERC20Token makerToken;
        IERC20Token takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        address maker;
        address taker;
        address txOrigin;
        uint256 expiryAndNonce; // [uint64 expiry, uint64 nonceBucket, uint128 nonce]
    }

    /// @dev Info on a limit or RFQ order.
    struct OrderInfo {
        bytes32 orderHash;
        OrderStatus status;
        uint128 takerTokenFilledAmount;
    }

    /// @dev Info on an OTC order.
    struct OtcOrderInfo {
        bytes32 orderHash;
        OrderStatus status;
    }

    uint256 private constant UINT_128_MASK = (1 << 128) - 1;
    uint256 private constant UINT_64_MASK = (1 << 64) - 1;
    uint256 private constant ADDRESS_MASK = (1 << 160) - 1;

    // The type hash for limit orders, which is:
    // keccak256(abi.encodePacked(
    //     "LimitOrder(",
    //       "address makerToken,",
    //       "address takerToken,",
    //       "uint128 makerAmount,",
    //       "uint128 takerAmount,",
    //       "uint128 takerTokenFeeAmount,",
    //       "address maker,",
    //       "address taker,",
    //       "address sender,",
    //       "address feeRecipient,",
    //       "bytes32 pool,",
    //       "uint64 expiry,",
    //       "uint256 salt"
    //     ")"
    // ))
    uint256 private constant _LIMIT_ORDER_TYPEHASH = 0xce918627cb55462ddbb85e73de69a8b322f2bc88f4507c52fcad6d4c33c29d49;

    // The type hash for RFQ orders, which is:
    // keccak256(abi.encodePacked(
    //     "RfqOrder(",
    //       "address makerToken,",
    //       "address takerToken,",
    //       "uint128 makerAmount,",
    //       "uint128 takerAmount,",
    //       "address maker,",
    //       "address taker,",
    //       "address txOrigin,",
    //       "bytes32 pool,",
    //       "uint64 expiry,",
    //       "uint256 salt"
    //     ")"
    // ))
    uint256 private constant _RFQ_ORDER_TYPEHASH = 0xe593d3fdfa8b60e5e17a1b2204662ecbe15c23f2084b9ad5bae40359540a7da9;

    // The type hash for OTC orders, which is:
    // keccak256(abi.encodePacked(
    //     "OtcOrder(",
    //       "address makerToken,",
    //       "address takerToken,",
    //       "uint128 makerAmount,",
    //       "uint128 takerAmount,",
    //       "address maker,",
    //       "address taker,",
    //       "address txOrigin,",
    //       "uint256 expiryAndNonce"
    //     ")"
    // ))
    uint256 private constant _OTC_ORDER_TYPEHASH = 0x2f754524de756ae72459efbe1ec88c19a745639821de528ac3fb88f9e65e35c8;

    /// @dev Get the struct hash of a limit order.
    /// @param order The limit order.
    /// @return structHash The struct hash of the order.
    function getLimitOrderStructHash(LimitOrder memory order) internal pure returns (bytes32 structHash) {
        // The struct hash is:
        // keccak256(abi.encode(
        //   TYPE_HASH,
        //   order.makerToken,
        //   order.takerToken,
        //   order.makerAmount,
        //   order.takerAmount,
        //   order.takerTokenFeeAmount,
        //   order.maker,
        //   order.taker,
        //   order.sender,
        //   order.feeRecipient,
        //   order.pool,
        //   order.expiry,
        //   order.salt,
        // ))
        assembly {
            let mem := mload(0x40)
            mstore(mem, _LIMIT_ORDER_TYPEHASH)
            // order.makerToken;
            mstore(add(mem, 0x20), and(ADDRESS_MASK, mload(order)))
            // order.takerToken;
            mstore(add(mem, 0x40), and(ADDRESS_MASK, mload(add(order, 0x20))))
            // order.makerAmount;
            mstore(add(mem, 0x60), and(UINT_128_MASK, mload(add(order, 0x40))))
            // order.takerAmount;
            mstore(add(mem, 0x80), and(UINT_128_MASK, mload(add(order, 0x60))))
            // order.takerTokenFeeAmount;
            mstore(add(mem, 0xA0), and(UINT_128_MASK, mload(add(order, 0x80))))
            // order.maker;
            mstore(add(mem, 0xC0), and(ADDRESS_MASK, mload(add(order, 0xA0))))
            // order.taker;
            mstore(add(mem, 0xE0), and(ADDRESS_MASK, mload(add(order, 0xC0))))
            // order.sender;
            mstore(add(mem, 0x100), and(ADDRESS_MASK, mload(add(order, 0xE0))))
            // order.feeRecipient;
            mstore(add(mem, 0x120), and(ADDRESS_MASK, mload(add(order, 0x100))))
            // order.pool;
            mstore(add(mem, 0x140), mload(add(order, 0x120)))
            // order.expiry;
            mstore(add(mem, 0x160), and(UINT_64_MASK, mload(add(order, 0x140))))
            // order.salt;
            mstore(add(mem, 0x180), mload(add(order, 0x160)))
            structHash := keccak256(mem, 0x1A0)
        }
    }

    /// @dev Get the struct hash of a RFQ order.
    /// @param order The RFQ order.
    /// @return structHash The struct hash of the order.
    function getRfqOrderStructHash(RfqOrder memory order) internal pure returns (bytes32 structHash) {
        // The struct hash is:
        // keccak256(abi.encode(
        //   TYPE_HASH,
        //   order.makerToken,
        //   order.takerToken,
        //   order.makerAmount,
        //   order.takerAmount,
        //   order.maker,
        //   order.taker,
        //   order.txOrigin,
        //   order.pool,
        //   order.expiry,
        //   order.salt,
        // ))
        assembly {
            let mem := mload(0x40)
            mstore(mem, _RFQ_ORDER_TYPEHASH)
            // order.makerToken;
            mstore(add(mem, 0x20), and(ADDRESS_MASK, mload(order)))
            // order.takerToken;
            mstore(add(mem, 0x40), and(ADDRESS_MASK, mload(add(order, 0x20))))
            // order.makerAmount;
            mstore(add(mem, 0x60), and(UINT_128_MASK, mload(add(order, 0x40))))
            // order.takerAmount;
            mstore(add(mem, 0x80), and(UINT_128_MASK, mload(add(order, 0x60))))
            // order.maker;
            mstore(add(mem, 0xA0), and(ADDRESS_MASK, mload(add(order, 0x80))))
            // order.taker;
            mstore(add(mem, 0xC0), and(ADDRESS_MASK, mload(add(order, 0xA0))))
            // order.txOrigin;
            mstore(add(mem, 0xE0), and(ADDRESS_MASK, mload(add(order, 0xC0))))
            // order.pool;
            mstore(add(mem, 0x100), mload(add(order, 0xE0)))
            // order.expiry;
            mstore(add(mem, 0x120), and(UINT_64_MASK, mload(add(order, 0x100))))
            // order.salt;
            mstore(add(mem, 0x140), mload(add(order, 0x120)))
            structHash := keccak256(mem, 0x160)
        }
    }

    /// @dev Get the struct hash of an OTC order.
    /// @param order The OTC order.
    /// @return structHash The struct hash of the order.
    function getOtcOrderStructHash(OtcOrder memory order) internal pure returns (bytes32 structHash) {
        // The struct hash is:
        // keccak256(abi.encode(
        //   TYPE_HASH,
        //   order.makerToken,
        //   order.takerToken,
        //   order.makerAmount,
        //   order.takerAmount,
        //   order.maker,
        //   order.taker,
        //   order.txOrigin,
        //   order.expiryAndNonce,
        // ))
        assembly {
            let mem := mload(0x40)
            mstore(mem, _OTC_ORDER_TYPEHASH)
            // order.makerToken;
            mstore(add(mem, 0x20), and(ADDRESS_MASK, mload(order)))
            // order.takerToken;
            mstore(add(mem, 0x40), and(ADDRESS_MASK, mload(add(order, 0x20))))
            // order.makerAmount;
            mstore(add(mem, 0x60), and(UINT_128_MASK, mload(add(order, 0x40))))
            // order.takerAmount;
            mstore(add(mem, 0x80), and(UINT_128_MASK, mload(add(order, 0x60))))
            // order.maker;
            mstore(add(mem, 0xA0), and(ADDRESS_MASK, mload(add(order, 0x80))))
            // order.taker;
            mstore(add(mem, 0xC0), and(ADDRESS_MASK, mload(add(order, 0xA0))))
            // order.txOrigin;
            mstore(add(mem, 0xE0), and(ADDRESS_MASK, mload(add(order, 0xC0))))
            // order.expiryAndNonce;
            mstore(add(mem, 0x100), mload(add(order, 0xE0)))
            structHash := keccak256(mem, 0x120)
        }
    }

    /// @dev Refund any leftover protocol fees in `msg.value` to `msg.sender`.
    /// @param ethProtocolFeePaid How much ETH was paid in protocol fees.
    function refundExcessProtocolFeeToSender(uint256 ethProtocolFeePaid) internal {
        if (msg.value > ethProtocolFeePaid && msg.sender != address(this)) {
            uint256 refundAmount = msg.value.safeSub(ethProtocolFeePaid);
            (bool success, ) = msg.sender.call{value: refundAmount}("");
            if (!success) {
                LibNativeOrdersRichErrors.ProtocolFeeRefundFailed(msg.sender, refundAmount).rrevert();
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibNativeOrdersRichErrors {
    function ProtocolFeeRefundFailed(address receiver, uint256 refundAmount) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("ProtocolFeeRefundFailed(address,uint256)")),
                receiver,
                refundAmount
            );
    }

    function OrderNotFillableByOriginError(
        bytes32 orderHash,
        address txOrigin,
        address orderTxOrigin
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("OrderNotFillableByOriginError(bytes32,address,address)")),
                orderHash,
                txOrigin,
                orderTxOrigin
            );
    }

    function OrderNotFillableError(bytes32 orderHash, uint8 orderStatus) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(bytes4(keccak256("OrderNotFillableError(bytes32,uint8)")), orderHash, orderStatus);
    }

    function OrderNotSignedByMakerError(
        bytes32 orderHash,
        address signer,
        address maker
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("OrderNotSignedByMakerError(bytes32,address,address)")),
                orderHash,
                signer,
                maker
            );
    }

    function InvalidSignerError(address maker, address signer) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("InvalidSignerError(address,address)")), maker, signer);
    }

    function OrderNotFillableBySenderError(
        bytes32 orderHash,
        address sender,
        address orderSender
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("OrderNotFillableBySenderError(bytes32,address,address)")),
                orderHash,
                sender,
                orderSender
            );
    }

    function OrderNotFillableByTakerError(
        bytes32 orderHash,
        address taker,
        address orderTaker
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("OrderNotFillableByTakerError(bytes32,address,address)")),
                orderHash,
                taker,
                orderTaker
            );
    }

    function CancelSaltTooLowError(uint256 minValidSalt, uint256 oldMinValidSalt) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("CancelSaltTooLowError(uint256,uint256)")),
                minValidSalt,
                oldMinValidSalt
            );
    }

    function FillOrKillFailedError(
        bytes32 orderHash,
        uint256 takerTokenFilledAmount,
        uint256 takerTokenFillAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("FillOrKillFailedError(bytes32,uint256,uint256)")),
                orderHash,
                takerTokenFilledAmount,
                takerTokenFillAmount
            );
    }

    function OnlyOrderMakerAllowed(
        bytes32 orderHash,
        address sender,
        address maker
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("OnlyOrderMakerAllowed(bytes32,address,address)")),
                orderHash,
                sender,
                maker
            );
    }

    function BatchFillIncompleteError(
        bytes32 orderHash,
        uint256 takerTokenFilledAmount,
        uint256 takerTokenFillAmount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("BatchFillIncompleteError(bytes32,uint256,uint256)")),
                orderHash,
                takerTokenFilledAmount,
                takerTokenFillAmount
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "../../errors/LibSignatureRichErrors.sol";

/// @dev A library for validating signatures.
library LibSignature {
    using LibRichErrorsV06 for bytes;

    // '\x19Ethereum Signed Message:\n32\x00\x00\x00\x00' in a word.
    uint256 private constant ETH_SIGN_HASH_PREFIX = 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000;
    /// @dev Exclusive upper limit on ECDSA signatures 'R' values.
    ///      The valid range is given by fig (282) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_R_LIMIT =
        uint256(0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141);
    /// @dev Exclusive upper limit on ECDSA signatures 'S' values.
    ///      The valid range is given by fig (283) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_S_LIMIT = ECDSA_SIGNATURE_R_LIMIT / 2 + 1;

    /// @dev Allowed signature types.
    enum SignatureType {
        ILLEGAL,
        INVALID,
        EIP712,
        ETHSIGN,
        PRESIGNED
    }

    /// @dev Encoded EC signature.
    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }

    /// @dev Retrieve the signer of a signature.
    ///      Throws if the signature can't be validated.
    /// @param hash The hash that was signed.
    /// @param signature The signature.
    /// @return recovered The recovered signer address.
    function getSignerOfHash(bytes32 hash, Signature memory signature) internal pure returns (address recovered) {
        // Ensure this is a signature type that can be validated against a hash.
        _validateHashCompatibleSignature(hash, signature);

        if (signature.signatureType == SignatureType.EIP712) {
            // Signed using EIP712
            recovered = ecrecover(hash, signature.v, signature.r, signature.s);
        } else if (signature.signatureType == SignatureType.ETHSIGN) {
            // Signed using `eth_sign`
            // Need to hash `hash` with "\x19Ethereum Signed Message:\n32" prefix
            // in packed encoding.
            bytes32 ethSignHash;
            assembly {
                // Use scratch space
                mstore(0, ETH_SIGN_HASH_PREFIX) // length of 28 bytes
                mstore(28, hash) // length of 32 bytes
                ethSignHash := keccak256(0, 60)
            }
            recovered = ecrecover(ethSignHash, signature.v, signature.r, signature.s);
        }
        // `recovered` can be null if the signature values are out of range.
        if (recovered == address(0)) {
            LibSignatureRichErrors
                .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.BAD_SIGNATURE_DATA, hash)
                .rrevert();
        }
    }

    /// @dev Validates that a signature is compatible with a hash signee.
    /// @param hash The hash that was signed.
    /// @param signature The signature.
    function _validateHashCompatibleSignature(bytes32 hash, Signature memory signature) private pure {
        // Ensure the r and s are within malleability limits.
        if (uint256(signature.r) >= ECDSA_SIGNATURE_R_LIMIT || uint256(signature.s) >= ECDSA_SIGNATURE_S_LIMIT) {
            LibSignatureRichErrors
                .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.BAD_SIGNATURE_DATA, hash)
                .rrevert();
        }

        // Always illegal signature.
        if (signature.signatureType == SignatureType.ILLEGAL) {
            LibSignatureRichErrors
                .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.ILLEGAL, hash)
                .rrevert();
        }

        // Always invalid.
        if (signature.signatureType == SignatureType.INVALID) {
            LibSignatureRichErrors
                .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.ALWAYS_INVALID, hash)
                .rrevert();
        }

        // If a feature supports pre-signing, it wouldn't use
        // `getSignerOfHash` on a pre-signed order.
        if (signature.signatureType == SignatureType.PRESIGNED) {
            LibSignatureRichErrors
                .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.UNSUPPORTED, hash)
                .rrevert();
        }

        // Solidity should check that the signature type is within enum range for us
        // when abi-decoding.
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;

library LibSignatureRichErrors {
    enum SignatureValidationErrorCodes {
        ALWAYS_INVALID,
        INVALID_LENGTH,
        UNSUPPORTED,
        ILLEGAL,
        WRONG_SIGNER,
        BAD_SIGNATURE_DATA
    }

    function SignatureValidationError(
        SignatureValidationErrorCodes code,
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("SignatureValidationError(uint8,bytes32,address,bytes)")),
                code,
                hash,
                signerAddress,
                signature
            );
    }

    function SignatureValidationError(
        SignatureValidationErrorCodes code,
        bytes32 hash
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("SignatureValidationError(uint8,bytes32)")), code, hash);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinEIP712.sol";
import "../interfaces/IMultiplexFeature.sol";
import "../interfaces/INativeOrdersFeature.sol";
import "../libs/LibNativeOrder.sol";

abstract contract MultiplexRfq is FixinEIP712 {
    using LibSafeMathV06 for uint256;

    event ExpiredRfqOrder(bytes32 orderHash, address maker, uint64 expiry);

    function _batchSellRfqOrder(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        // Decode the RFQ order and signature.
        (LibNativeOrder.RfqOrder memory order, LibSignature.Signature memory signature) = abi.decode(
            wrappedCallData,
            (LibNativeOrder.RfqOrder, LibSignature.Signature)
        );
        // Pre-emptively check if the order is expired.
        if (order.expiry <= uint64(block.timestamp)) {
            bytes32 orderHash = _getEIP712Hash(LibNativeOrder.getRfqOrderStructHash(order));
            emit ExpiredRfqOrder(orderHash, order.maker, order.expiry);
            return;
        }
        // Validate tokens.
        require(
            order.takerToken == params.inputToken && order.makerToken == params.outputToken,
            "MultiplexRfq::_batchSellRfqOrder/RFQ_ORDER_INVALID_TOKENS"
        );
        // Try filling the RFQ order. Swallows reverts.
        try
            INativeOrdersFeature(address(this))._fillRfqOrder(
                order,
                signature,
                sellAmount.safeDowncastToUint128(),
                params.payer,
                params.useSelfBalance,
                params.recipient
            )
        returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount) {
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(takerTokenFilledAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(makerTokenFilledAmount);
        } catch {}
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/src/IERC20Token.sol";
import "../libs/LibSignature.sol";
import "../libs/LibNativeOrder.sol";
import "./INativeOrdersEvents.sol";

/// @dev Feature for interacting with limit orders.
interface INativeOrdersFeature is INativeOrdersEvents {
    /// @dev Transfers protocol fees from the `FeeCollector` pools into
    ///      the staking contract.
    /// @param poolIds Staking pool IDs
    function transferProtocolFeesForPools(bytes32[] calldata poolIds) external;

    /// @dev Fill a limit order. The taker and sender will be the caller.
    /// @param order The limit order. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      the caller.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this order with.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillLimitOrder(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    ) external payable returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order for up to `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token amount to fill this order with.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillRfqOrder(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    ) external returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order for exactly `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      the caller.
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount How much taker token to fill this order with.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOrKillLimitOrder(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    ) external payable returns (uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order for exactly `takerTokenFillAmount` taker tokens.
    ///      The taker will be the caller.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount How much taker token to fill this order with.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function fillOrKillRfqOrder(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount
    ) external returns (uint128 makerTokenFilledAmount);

    /// @dev Fill a limit order. Internal variant. ETH protocol fees can be
    ///      attached to this call. Any unspent ETH will be refunded to
    ///      `msg.sender` (not `sender`).
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token to fill this order with.
    /// @param taker The order taker.
    /// @param sender The order sender.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillLimitOrder(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount,
        address taker,
        address sender
    ) external payable returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Fill an RFQ order. Internal variant.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @param takerTokenFillAmount Maximum taker token to fill this order with.
    /// @param taker The order taker.
    /// @param useSelfBalance Whether to use the ExchangeProxy's transient
    ///        balance of taker tokens to fill the order.
    /// @param recipient The recipient of the maker tokens.
    /// @return takerTokenFilledAmount How much maker token was filled.
    /// @return makerTokenFilledAmount How much maker token was filled.
    function _fillRfqOrder(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature,
        uint128 takerTokenFillAmount,
        address taker,
        bool useSelfBalance,
        address recipient
    ) external returns (uint128 takerTokenFilledAmount, uint128 makerTokenFilledAmount);

    /// @dev Cancel a single limit order. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param order The limit order.
    function cancelLimitOrder(LibNativeOrder.LimitOrder calldata order) external;

    /// @dev Cancel a single RFQ order. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param order The RFQ order.
    function cancelRfqOrder(LibNativeOrder.RfqOrder calldata order) external;

    /// @dev Mark what tx.origin addresses are allowed to fill an order that
    ///      specifies the message sender as its txOrigin.
    /// @param origins An array of origin addresses to update.
    /// @param allowed True to register, false to unregister.
    function registerAllowedRfqOrigins(address[] memory origins, bool allowed) external;

    /// @dev Cancel multiple limit orders. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param orders The limit orders.
    function batchCancelLimitOrders(LibNativeOrder.LimitOrder[] calldata orders) external;

    /// @dev Cancel multiple RFQ orders. The caller must be the maker or a valid order signer.
    ///      Silently succeeds if the order has already been cancelled.
    /// @param orders The RFQ orders.
    function batchCancelRfqOrders(LibNativeOrder.RfqOrder[] calldata orders) external;

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairLimitOrders(IERC20Token makerToken, IERC20Token takerToken, uint256 minValidSalt) external;

    /// @dev Cancel all limit orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairLimitOrdersWithSigner(
        address maker,
        IERC20Token makerToken,
        IERC20Token takerToken,
        uint256 minValidSalt
    ) external;

    /// @dev Cancel all limit orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairLimitOrders(
        IERC20Token[] calldata makerTokens,
        IERC20Token[] calldata takerTokens,
        uint256[] calldata minValidSalts
    ) external;

    /// @dev Cancel all limit orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairLimitOrdersWithSigner(
        address maker,
        IERC20Token[] memory makerTokens,
        IERC20Token[] memory takerTokens,
        uint256[] memory minValidSalts
    ) external;

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairRfqOrders(IERC20Token makerToken, IERC20Token takerToken, uint256 minValidSalt) external;

    /// @dev Cancel all RFQ orders for a given maker and pair with a salt less
    ///      than the value provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerToken The maker token.
    /// @param takerToken The taker token.
    /// @param minValidSalt The new minimum valid salt.
    function cancelPairRfqOrdersWithSigner(
        address maker,
        IERC20Token makerToken,
        IERC20Token takerToken,
        uint256 minValidSalt
    ) external;

    /// @dev Cancel all RFQ orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be the maker. Subsequent
    ///      calls to this function with the same caller and pair require the
    ///      new salt to be >= the old salt.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairRfqOrders(
        IERC20Token[] calldata makerTokens,
        IERC20Token[] calldata takerTokens,
        uint256[] calldata minValidSalts
    ) external;

    /// @dev Cancel all RFQ orders for a given maker and pairs with salts less
    ///      than the values provided. The caller must be a signer registered to the maker.
    ///      Subsequent calls to this function with the same maker and pair require the
    ///      new salt to be >= the old salt.
    /// @param maker The maker for which to cancel.
    /// @param makerTokens The maker tokens.
    /// @param takerTokens The taker tokens.
    /// @param minValidSalts The new minimum valid salts.
    function batchCancelPairRfqOrdersWithSigner(
        address maker,
        IERC20Token[] memory makerTokens,
        IERC20Token[] memory takerTokens,
        uint256[] memory minValidSalts
    ) external;

    /// @dev Get the order info for a limit order.
    /// @param order The limit order.
    /// @return orderInfo Info about the order.
    function getLimitOrderInfo(
        LibNativeOrder.LimitOrder calldata order
    ) external view returns (LibNativeOrder.OrderInfo memory orderInfo);

    /// @dev Get the order info for an RFQ order.
    /// @param order The RFQ order.
    /// @return orderInfo Info about the order.
    function getRfqOrderInfo(
        LibNativeOrder.RfqOrder calldata order
    ) external view returns (LibNativeOrder.OrderInfo memory orderInfo);

    /// @dev Get the canonical hash of a limit order.
    /// @param order The limit order.
    /// @return orderHash The order hash.
    function getLimitOrderHash(LibNativeOrder.LimitOrder calldata order) external view returns (bytes32 orderHash);

    /// @dev Get the canonical hash of an RFQ order.
    /// @param order The RFQ order.
    /// @return orderHash The order hash.
    function getRfqOrderHash(LibNativeOrder.RfqOrder calldata order) external view returns (bytes32 orderHash);

    /// @dev Get the protocol fee multiplier. This should be multiplied by the
    ///      gas price to arrive at the required protocol fee to fill a native order.
    /// @return multiplier The protocol fee multiplier.
    function getProtocolFeeMultiplier() external view returns (uint32 multiplier);

    /// @dev Get order info, fillable amount, and signature validity for a limit order.
    ///      Fillable amount is determined using balances and allowances of the maker.
    /// @param order The limit order.
    /// @param signature The order signature.
    /// @return orderInfo Info about the order.
    /// @return actualFillableTakerTokenAmount How much of the order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValid Whether the signature is valid.
    function getLimitOrderRelevantState(
        LibNativeOrder.LimitOrder calldata order,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo memory orderInfo,
            uint128 actualFillableTakerTokenAmount,
            bool isSignatureValid
        );

    /// @dev Get order info, fillable amount, and signature validity for an RFQ order.
    ///      Fillable amount is determined using balances and allowances of the maker.
    /// @param order The RFQ order.
    /// @param signature The order signature.
    /// @return orderInfo Info about the order.
    /// @return actualFillableTakerTokenAmount How much of the order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValid Whether the signature is valid.
    function getRfqOrderRelevantState(
        LibNativeOrder.RfqOrder calldata order,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo memory orderInfo,
            uint128 actualFillableTakerTokenAmount,
            bool isSignatureValid
        );

    /// @dev Batch version of `getLimitOrderRelevantState()`, without reverting.
    ///      Orders that would normally cause `getLimitOrderRelevantState()`
    ///      to revert will have empty results.
    /// @param orders The limit orders.
    /// @param signatures The order signatures.
    /// @return orderInfos Info about the orders.
    /// @return actualFillableTakerTokenAmounts How much of each order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValids Whether each signature is valid for the order.
    function batchGetLimitOrderRelevantStates(
        LibNativeOrder.LimitOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo[] memory orderInfos,
            uint128[] memory actualFillableTakerTokenAmounts,
            bool[] memory isSignatureValids
        );

    /// @dev Batch version of `getRfqOrderRelevantState()`, without reverting.
    ///      Orders that would normally cause `getRfqOrderRelevantState()`
    ///      to revert will have empty results.
    /// @param orders The RFQ orders.
    /// @param signatures The order signatures.
    /// @return orderInfos Info about the orders.
    /// @return actualFillableTakerTokenAmounts How much of each order is fillable
    ///         based on maker funds, in taker tokens.
    /// @return isSignatureValids Whether each signature is valid for the order.
    function batchGetRfqOrderRelevantStates(
        LibNativeOrder.RfqOrder[] calldata orders,
        LibSignature.Signature[] calldata signatures
    )
        external
        view
        returns (
            LibNativeOrder.OrderInfo[] memory orderInfos,
            uint128[] memory actualFillableTakerTokenAmounts,
            bool[] memory isSignatureValids
        );

    /// @dev Register a signer who can sign on behalf of msg.sender
    ///      This allows one to sign on behalf of a contract that calls this function
    /// @param signer The address from which you plan to generate signatures
    /// @param allowed True to register, false to unregister.
    function registerAllowedOrderSigner(address signer, bool allowed) external;

    /// @dev checks if a given address is registered to sign on behalf of a maker address
    /// @param maker The maker address encoded in an order (can be a contract)
    /// @param signer The address that is providing a signature
    function isValidOrderSigner(address maker, address signer) external view returns (bool isAllowed);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "../libs/LibSignature.sol";
import "../libs/LibNativeOrder.sol";

/// @dev Events emitted by NativeOrdersFeature.
interface INativeOrdersEvents {
    /// @dev Emitted whenever a `LimitOrder` is filled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param feeRecipient Fee recipient of the order.
    /// @param takerTokenFilledAmount How much taker token was filled.
    /// @param makerTokenFilledAmount How much maker token was filled.
    /// @param protocolFeePaid How much protocol fee was paid.
    /// @param pool The fee pool associated with this order.
    event LimitOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address feeRecipient,
        address makerToken,
        address takerToken,
        uint128 takerTokenFilledAmount,
        uint128 makerTokenFilledAmount,
        uint128 takerTokenFeeFilledAmount,
        uint256 protocolFeePaid,
        bytes32 pool
    );

    /// @dev Emitted whenever an `RfqOrder` is filled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The maker of the order.
    /// @param taker The taker of the order.
    /// @param takerTokenFilledAmount How much taker token was filled.
    /// @param makerTokenFilledAmount How much maker token was filled.
    /// @param pool The fee pool associated with this order.
    event RfqOrderFilled(
        bytes32 orderHash,
        address maker,
        address taker,
        address makerToken,
        address takerToken,
        uint128 takerTokenFilledAmount,
        uint128 makerTokenFilledAmount,
        bytes32 pool
    );

    /// @dev Emitted whenever a limit or RFQ order is cancelled.
    /// @param orderHash The canonical hash of the order.
    /// @param maker The order maker.
    event OrderCancelled(bytes32 orderHash, address maker);

    /// @dev Emitted whenever Limit orders are cancelled by pair by a maker.
    /// @param maker The maker of the order.
    /// @param makerToken The maker token in a pair for the orders cancelled.
    /// @param takerToken The taker token in a pair for the orders cancelled.
    /// @param minValidSalt The new minimum valid salt an order with this pair must
    ///        have.
    event PairCancelledLimitOrders(address maker, address makerToken, address takerToken, uint256 minValidSalt);

    /// @dev Emitted whenever RFQ orders are cancelled by pair by a maker.
    /// @param maker The maker of the order.
    /// @param makerToken The maker token in a pair for the orders cancelled.
    /// @param takerToken The taker token in a pair for the orders cancelled.
    /// @param minValidSalt The new minimum valid salt an order with this pair must
    ///        have.
    event PairCancelledRfqOrders(address maker, address makerToken, address takerToken, uint256 minValidSalt);

    /// @dev Emitted when new addresses are allowed or disallowed to fill
    ///      orders with a given txOrigin.
    /// @param origin The address doing the allowing.
    /// @param addrs The address being allowed/disallowed.
    /// @param allowed Indicates whether the address should be allowed.
    event RfqOrderOriginsAllowed(address origin, address[] addrs, bool allowed);

    /// @dev Emitted when new order signers are registered
    /// @param maker The maker address that is registering a designated signer.
    /// @param signer The address that will sign on behalf of maker.
    /// @param allowed Indicates whether the address should be allowed.
    event OrderSignerRegistered(address maker, address signer, bool allowed);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../interfaces/IMultiplexFeature.sol";
import "../interfaces/ITransformERC20Feature.sol";

abstract contract MultiplexTransformERC20 {
    using LibSafeMathV06 for uint256;

    function _batchSellTransformERC20(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        ITransformERC20Feature.TransformERC20Args memory args;
        // We want the TransformedERC20 event to have
        // `payer` as the taker.
        args.taker = payable(params.payer);
        args.inputToken = params.inputToken;
        args.outputToken = params.outputToken;
        args.inputTokenAmount = sellAmount;
        args.minOutputTokenAmount = 0;
        args.useSelfBalance = params.useSelfBalance;
        args.recipient = payable(params.recipient);
        (args.transformations) = abi.decode(wrappedCallData, (ITransformERC20Feature.Transformation[]));
        // Execute the transformations and swallow reverts.
        try ITransformERC20Feature(address(this))._transformERC20(args) returns (uint256 outputTokenAmount) {
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(sellAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(outputTokenAmount);
        } catch {}
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/src/IERC20Token.sol";
import "../../transformers/IERC20Transformer.sol";
import "../../external/IFlashWallet.sol";

/// @dev Feature to composably transform between ERC20 tokens.
interface ITransformERC20Feature {
    /// @dev Defines a transformation to run in `transformERC20()`.
    struct Transformation {
        // The deployment nonce for the transformer.
        // The address of the transformer contract will be derived from this
        // value.
        uint32 deploymentNonce;
        // Arbitrary data to pass to the transformer.
        bytes data;
    }

    /// @dev Arguments for `_transformERC20()`.
    struct TransformERC20Args {
        // The taker address.
        address payable taker;
        // The token being provided by the taker.
        // If `0xeee...`, ETH is implied and should be provided with the call.`
        IERC20Token inputToken;
        // The token to be acquired by the taker.
        // `0xeee...` implies ETH.
        IERC20Token outputToken;
        // The amount of `inputToken` to take from the taker.
        // If set to `uint256(-1)`, the entire spendable balance of the taker
        // will be solt.
        uint256 inputTokenAmount;
        // The minimum amount of `outputToken` the taker
        // must receive for the entire transformation to succeed. If set to zero,
        // the minimum output token transfer will not be asserted.
        uint256 minOutputTokenAmount;
        // The transformations to execute on the token balance(s)
        // in sequence.
        Transformation[] transformations;
        // Whether to use the Exchange Proxy's balance of `inputToken`.
        bool useSelfBalance;
        // The recipient of the bought `outputToken`.
        address payable recipient;
    }

    /// @dev Raised upon a successful `transformERC20`.
    /// @param taker The taker (caller) address.
    /// @param inputToken The token being provided by the taker.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the taker.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the taker.
    /// @param outputTokenAmount The amount of `outputToken` received by the taker.
    event TransformedERC20(
        address indexed taker,
        address inputToken,
        address outputToken,
        uint256 inputTokenAmount,
        uint256 outputTokenAmount
    );

    /// @dev Raised when `setTransformerDeployer()` is called.
    /// @param transformerDeployer The new deployer address.
    event TransformerDeployerUpdated(address transformerDeployer);

    /// @dev Raised when `setQuoteSigner()` is called.
    /// @param quoteSigner The new quote signer.
    event QuoteSignerUpdated(address quoteSigner);

    /// @dev Replace the allowed deployer for transformers.
    ///      Only callable by the owner.
    /// @param transformerDeployer The address of the new trusted deployer
    ///        for transformers.
    function setTransformerDeployer(address transformerDeployer) external;

    /// @dev Replace the optional signer for `transformERC20()` calldata.
    ///      Only callable by the owner.
    /// @param quoteSigner The address of the new calldata signer.
    function setQuoteSigner(address quoteSigner) external;

    /// @dev Deploy a new flash wallet instance and replace the current one with it.
    ///      Useful if we somehow break the current wallet instance.
    ///       Only callable by the owner.
    /// @return wallet The new wallet instance.
    function createTransformWallet() external returns (IFlashWallet wallet);

    /// @dev Executes a series of transformations to convert an ERC20 `inputToken`
    ///      to an ERC20 `outputToken`.
    /// @param inputToken The token being provided by the sender.
    ///        If `0xeee...`, ETH is implied and should be provided with the call.`
    /// @param outputToken The token to be acquired by the sender.
    ///        `0xeee...` implies ETH.
    /// @param inputTokenAmount The amount of `inputToken` to take from the sender.
    /// @param minOutputTokenAmount The minimum amount of `outputToken` the sender
    ///        must receive for the entire transformation to succeed.
    /// @param transformations The transformations to execute on the token balance(s)
    ///        in sequence.
    /// @return outputTokenAmount The amount of `outputToken` received by the sender.
    function transformERC20(
        IERC20Token inputToken,
        IERC20Token outputToken,
        uint256 inputTokenAmount,
        uint256 minOutputTokenAmount,
        Transformation[] calldata transformations
    ) external payable returns (uint256 outputTokenAmount);

    /// @dev Internal version of `transformERC20()`. Only callable from within.
    /// @param args A `TransformERC20Args` struct.
    /// @return outputTokenAmount The amount of `outputToken` received by the taker.
    function _transformERC20(TransformERC20Args calldata args) external payable returns (uint256 outputTokenAmount);

    /// @dev Return the current wallet instance that will serve as the execution
    ///      context for transformations.
    /// @return wallet The wallet instance.
    function getTransformWallet() external view returns (IFlashWallet wallet);

    /// @dev Return the allowed deployer for transformers.
    /// @return deployer The transform deployer address.
    function getTransformerDeployer() external view returns (address deployer);

    /// @dev Return the optional signer for `transformERC20()` calldata.
    /// @return signer The transform deployer address.
    function getQuoteSigner() external view returns (address signer);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

/// @dev A transformation callback used in `TransformERC20.transformERC20()`.
interface IERC20Transformer {
    /// @dev Context information to pass into `transform()` by `TransformERC20.transformERC20()`.
    struct TransformContext {
        // The caller of `TransformERC20.transformERC20()`.
        address payable sender;
        // The recipient address, which may be distinct from `sender` e.g. in
        // meta-transactions.
        address payable recipient;
        // Arbitrary data to pass to the transformer.
        bytes data;
    }

    /// @dev Called from `TransformERC20.transformERC20()`. This will be
    ///      delegatecalled in the context of the FlashWallet instance being used.
    /// @param context Context information.
    /// @return success The success bytes (`LibERC20Transformer.TRANSFORMER_SUCCESS`).
    function transform(TransformContext calldata context) external returns (bytes4 success);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/interfaces/IOwnableV06.sol";

/// @dev A contract that can execute arbitrary calls from its owner.
interface IFlashWallet {
    /// @dev Execute an arbitrary call. Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @param value Ether to attach to the call.
    /// @return resultData The data returned by the call.
    function executeCall(
        address payable target,
        bytes calldata callData,
        uint256 value
    ) external payable returns (bytes memory resultData);

    /// @dev Execute an arbitrary delegatecall, in the context of this puppet.
    ///      Only an authority can call this.
    /// @param target The call target.
    /// @param callData The call data.
    /// @return resultData The data returned by the call.
    function executeDelegateCall(
        address payable target,
        bytes calldata callData
    ) external payable returns (bytes memory resultData);

    /// @dev Allows the puppet to receive ETH.
    receive() external payable;

    /// @dev Fetch the immutable owner/deployer of this contract.
    /// @return owner_ The immutable owner/deployer/
    function owner() external view returns (address owner_);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/src/IERC20Token.sol";
import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinCommon.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../../vendor/IUniswapV2Pair.sol";
import "../interfaces/IMultiplexFeature.sol";

abstract contract MultiplexUniswapV2 is FixinCommon, FixinTokenSpender {
    using LibSafeMathV06 for uint256;

    // address of the UniswapV2Factory contract.
    address private immutable UNISWAP_FACTORY;
    // address of the (Sushiswap) UniswapV2Factory contract.
    address private immutable SUSHISWAP_FACTORY;
    // Init code hash of the UniswapV2Pair contract.
    bytes32 private immutable UNISWAP_PAIR_INIT_CODE_HASH;
    // Init code hash of the (Sushiswap) UniswapV2Pair contract.
    bytes32 private immutable SUSHISWAP_PAIR_INIT_CODE_HASH;

    constructor(
        address uniswapFactory,
        address sushiswapFactory,
        bytes32 uniswapPairInitCodeHash,
        bytes32 sushiswapPairInitCodeHash
    ) internal {
        UNISWAP_FACTORY = uniswapFactory;
        SUSHISWAP_FACTORY = sushiswapFactory;
        UNISWAP_PAIR_INIT_CODE_HASH = uniswapPairInitCodeHash;
        SUSHISWAP_PAIR_INIT_CODE_HASH = sushiswapPairInitCodeHash;
    }

    // A payable external function that we can delegatecall to
    // swallow reverts and roll back the input token transfer.
    function _batchSellUniswapV2External(
        IMultiplexFeature.BatchSellParams calldata params,
        bytes calldata wrappedCallData,
        uint256 sellAmount
    ) external payable returns (uint256 boughtAmount) {
        // Revert is not a delegatecall.
        require(
            address(this) != _implementation,
            "MultiplexLiquidityProvider::_batchSellUniswapV2External/ONLY_DELEGATECALL"
        );

        (address[] memory tokens, bool isSushi) = abi.decode(wrappedCallData, (address[], bool));
        // Validate tokens
        require(
            tokens.length >= 2 &&
                tokens[0] == address(params.inputToken) &&
                tokens[tokens.length - 1] == address(params.outputToken),
            "MultiplexUniswapV2::_batchSellUniswapV2/INVALID_TOKENS"
        );
        // Compute the address of the first Uniswap pair
        // contract that will execute a swap.
        address firstPairAddress = _computeUniswapPairAddress(tokens[0], tokens[1], isSushi);
        // `_sellToUniswapV2` assumes the input tokens have been
        // transferred into the pair contract before it is called,
        // so we transfer the tokens in now (either from `msg.sender`
        // or using the Exchange Proxy's balance).
        if (params.useSelfBalance) {
            _transferERC20Tokens(IERC20Token(tokens[0]), firstPairAddress, sellAmount);
        } else {
            _transferERC20TokensFrom(IERC20Token(tokens[0]), params.payer, firstPairAddress, sellAmount);
        }
        // Execute the Uniswap/Sushiswap trade.
        return _sellToUniswapV2(tokens, sellAmount, isSushi, firstPairAddress, params.recipient);
    }

    function _batchSellUniswapV2(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        // Swallow reverts
        (bool success, bytes memory resultData) = _implementation.delegatecall(
            abi.encodeWithSelector(this._batchSellUniswapV2External.selector, params, wrappedCallData, sellAmount)
        );
        if (success) {
            // Decode the output token amount on success.
            uint256 boughtAmount = abi.decode(resultData, (uint256));
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(sellAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(boughtAmount);
        }
    }

    function _multiHopSellUniswapV2(
        IMultiplexFeature.MultiHopSellState memory state,
        IMultiplexFeature.MultiHopSellParams memory params,
        bytes memory wrappedCallData
    ) internal {
        (address[] memory tokens, bool isSushi) = abi.decode(wrappedCallData, (address[], bool));
        // Validate the tokens
        require(
            tokens.length >= 2 &&
                tokens[0] == params.tokens[state.hopIndex] &&
                tokens[tokens.length - 1] == params.tokens[state.hopIndex + 1],
            "MultiplexUniswapV2::_multiHopSellUniswapV2/INVALID_TOKENS"
        );
        // Execute the Uniswap/Sushiswap trade.
        state.outputTokenAmount = _sellToUniswapV2(tokens, state.outputTokenAmount, isSushi, state.from, state.to);
    }

    function _sellToUniswapV2(
        address[] memory tokens,
        uint256 sellAmount,
        bool isSushi,
        address pairAddress,
        address recipient
    ) private returns (uint256 outputTokenAmount) {
        // Iterate through `tokens` perform a swap against the Uniswap
        // pair contract for each `(tokens[i], tokens[i+1])`.
        for (uint256 i = 0; i < tokens.length - 1; i++) {
            (address inputToken, address outputToken) = (tokens[i], tokens[i + 1]);
            // Compute the output token amount
            outputTokenAmount = _computeUniswapOutputAmount(pairAddress, inputToken, outputToken, sellAmount);
            (uint256 amount0Out, uint256 amount1Out) = inputToken < outputToken
                ? (uint256(0), outputTokenAmount)
                : (outputTokenAmount, uint256(0));
            // The Uniswap pair contract will transfer the output tokens to
            // the next pair contract if there is one, otherwise transfer to
            // `recipient`.
            address to = i < tokens.length - 2
                ? _computeUniswapPairAddress(outputToken, tokens[i + 2], isSushi)
                : recipient;
            // Execute the swap.
            IUniswapV2Pair(pairAddress).swap(amount0Out, amount1Out, to, new bytes(0));
            // To avoid recomputing the pair address of the next pair, store
            // `to` in `pairAddress`.
            pairAddress = to;
            // The outputTokenAmount
            sellAmount = outputTokenAmount;
        }
    }

    // Computes the Uniswap/Sushiswap pair contract address for the
    // given tokens.
    function _computeUniswapPairAddress(
        address tokenA,
        address tokenB,
        bool isSushi
    ) internal view returns (address pairAddress) {
        // Tokens are lexicographically sorted in the Uniswap contract.
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (isSushi) {
            // Use the Sushiswap factory address and codehash
            return
                address(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                SUSHISWAP_FACTORY,
                                keccak256(abi.encodePacked(token0, token1)),
                                SUSHISWAP_PAIR_INIT_CODE_HASH
                            )
                        )
                    )
                );
        } else {
            // Use the Uniswap factory address and codehash
            return
                address(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                UNISWAP_FACTORY,
                                keccak256(abi.encodePacked(token0, token1)),
                                UNISWAP_PAIR_INIT_CODE_HASH
                            )
                        )
                    )
                );
        }
    }

    // Computes the the amount of output token that would be bought
    // from Uniswap/Sushiswap given the input amount.
    function _computeUniswapOutputAmount(
        address pairAddress,
        address inputToken,
        address outputToken,
        uint256 inputAmount
    ) private view returns (uint256 outputAmount) {
        // Input amount should be non-zero.
        require(inputAmount > 0, "MultiplexUniswapV2::_computeUniswapOutputAmount/INSUFFICIENT_INPUT_AMOUNT");
        // Query the reserves of the pair contract.
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();
        // Reserves must be non-zero.
        require(reserve0 > 0 && reserve1 > 0, "MultiplexUniswapV2::_computeUniswapOutputAmount/INSUFFICIENT_LIQUIDITY");
        // Tokens are lexicographically sorted in the Uniswap contract.
        (uint256 inputReserve, uint256 outputReserve) = inputToken < outputToken
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        // Compute the output amount.
        uint256 inputAmountWithFee = inputAmount.safeMul(997);
        uint256 numerator = inputAmountWithFee.safeMul(outputReserve);
        uint256 denominator = inputReserve.safeMul(1000).safeAdd(inputAmountWithFee);
        return numerator / denominator;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.12;

interface IUniswapV2Pair {
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "@0x/contracts-utils/contracts/src/v06/LibSafeMathV06.sol";
import "../../fixins/FixinTokenSpender.sol";
import "../interfaces/IMultiplexFeature.sol";
import "../interfaces/IUniswapV3Feature.sol";

abstract contract MultiplexUniswapV3 is FixinTokenSpender {
    using LibSafeMathV06 for uint256;

    function _batchSellUniswapV3(
        IMultiplexFeature.BatchSellState memory state,
        IMultiplexFeature.BatchSellParams memory params,
        bytes memory wrappedCallData,
        uint256 sellAmount
    ) internal {
        bool success;
        bytes memory resultData;
        if (params.useSelfBalance) {
            // If the tokens are held by `address(this)`, we call
            // the `onlySelf` variant `_sellHeldTokenForTokenToUniswapV3`,
            // which uses the Exchange Proxy's balance of input token.
            (success, resultData) = address(this).call(
                abi.encodeWithSelector(
                    IUniswapV3Feature._sellHeldTokenForTokenToUniswapV3.selector,
                    wrappedCallData,
                    sellAmount,
                    0,
                    params.recipient
                )
            );
        } else {
            // Otherwise, we self-call `_sellTokenForTokenToUniswapV3`,
            // which pulls the input token from a specified `payer`.
            (success, resultData) = address(this).call(
                abi.encodeWithSelector(
                    IUniswapV3Feature._sellTokenForTokenToUniswapV3.selector,
                    wrappedCallData,
                    sellAmount,
                    0,
                    params.recipient,
                    params.payer
                )
            );
        }
        if (success) {
            // Decode the output token amount on success.
            uint256 outputTokenAmount = abi.decode(resultData, (uint256));
            // Increment the sold and bought amounts.
            state.soldAmount = state.soldAmount.safeAdd(sellAmount);
            state.boughtAmount = state.boughtAmount.safeAdd(outputTokenAmount);
        }
    }

    function _multiHopSellUniswapV3(
        IMultiplexFeature.MultiHopSellState memory state,
        IMultiplexFeature.MultiHopSellParams memory params,
        bytes memory wrappedCallData
    ) internal {
        bool success;
        bytes memory resultData;
        if (state.from == address(this)) {
            // If the tokens are held by `address(this)`, we call
            // the `onlySelf` variant `_sellHeldTokenForTokenToUniswapV3`,
            // which uses the Exchange Proxy's balance of input token.
            (success, resultData) = address(this).call(
                abi.encodeWithSelector(
                    IUniswapV3Feature._sellHeldTokenForTokenToUniswapV3.selector,
                    wrappedCallData,
                    state.outputTokenAmount,
                    0,
                    state.to
                )
            );
        } else {
            // Otherwise, we self-call `_sellTokenForTokenToUniswapV3`,
            // which pulls the input token from `payer`.
            (success, resultData) = address(this).call(
                abi.encodeWithSelector(
                    IUniswapV3Feature._sellTokenForTokenToUniswapV3.selector,
                    wrappedCallData,
                    state.outputTokenAmount,
                    0,
                    state.to,
                    params.payer
                )
            );
        }
        if (success) {
            // Decode the output token amount on success.
            state.outputTokenAmount = abi.decode(resultData, (uint256));
        } else {
            revert("MultiplexUniswapV3::_multiHopSellUniswapV3/SWAP_FAILED");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

/// @dev VIP uniswap v3 fill functions.
interface IUniswapV3Feature {
    /// @dev Sell attached ETH directly against uniswap v3.
    /// @param encodedPath Uniswap-encoded path, where the first token is WETH.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of the last token in the path bought.
    function sellEthForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 minBuyAmount,
        address recipient
    ) external payable returns (uint256 buyAmount);

    /// @dev Sell a token for ETH directly against uniswap v3.
    /// @param encodedPath Uniswap-encoded path, where the last token is WETH.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of ETH to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of ETH bought.
    function sellTokenForEthToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address payable recipient
    ) external returns (uint256 buyAmount);

    /// @dev Sell a token for another token directly against uniswap v3.
    /// @param encodedPath Uniswap-encoded path.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of the last token in the path bought.
    function sellTokenForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address recipient
    ) external returns (uint256 buyAmount);

    /// @dev Sell a token for another token directly against uniswap v3. Internal variant.
    /// @param encodedPath Uniswap-encoded path.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for payer.
    /// @param payer The address to pull the sold tokens from.
    /// @return buyAmount Amount of the last token in the path bought.
    function _sellTokenForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address recipient,
        address payer
    ) external returns (uint256 buyAmount);

    /// @dev Sell a token for another token directly against uniswap v3.
    ///      Private variant, uses tokens held by `address(this)`.
    /// @param encodedPath Uniswap-encoded path.
    /// @param sellAmount amount of the first token in the path to sell.
    /// @param minBuyAmount Minimum amount of the last token in the path to buy.
    /// @param recipient The recipient of the bought tokens. Can be zero for sender.
    /// @return buyAmount Amount of the last token in the path bought.
    function _sellHeldTokenForTokenToUniswapV3(
        bytes memory encodedPath,
        uint256 sellAmount,
        uint256 minBuyAmount,
        address recipient
    ) external returns (uint256 buyAmount);

    /// @dev The UniswapV3 pool swap callback which pays the funds requested
    ///      by the caller/pool to the pool. Can only be called by a valid
    ///      UniswapV3 pool.
    /// @param amount0Delta Token0 amount owed.
    /// @param amount1Delta Token1 amount owed.
    /// @param data Arbitrary data forwarded from swap() caller. An ABI-encoded
    ///        struct of: inputToken, outputToken, fee, payer
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}