// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

import "./ProxyErrors.sol";

import "./structs/ProxyStruct.sol";
import "./structs/ZeroExStruct.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@swaap-labs/swaap-core-v1/contracts/interfaces/IFactory.sol";
import "@swaap-labs/swaap-core-v1/contracts/interfaces/IPool.sol";
import "@swaap-labs/swaap-core-v1/contracts/structs/Struct.sol";

import "./interfaces/IProxy.sol";
import "./interfaces/IProxyOwner.sol";

import "./interfaces/IERC20WithDecimals.sol";
import "./interfaces/IWrappedERC20.sol";

contract Proxy is IProxy, IProxyOwner {

    using SafeERC20 for IERC20;

    modifier _beforeDeadline(uint256 deadline) {
        _require(block.timestamp <= deadline, ProxyErr.PASSED_DEADLINE);
        _;
    }

    bool internal locked;
    modifier _lock() {
        _require(!locked, ProxyErr.REENTRY);
        locked = true;
        _;
        locked = false;
    }

    enum Aggregator {
        ZeroEx,
        Paraswap,
        OneInch
    }

    bool    private paused;
    address private swaaplabs;
    address private pendingSwaaplabs;
    
    address immutable private wnative;
    address constant  private NATIVE_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint256 constant  private ONE = 10 ** 18;
    address immutable private zeroEx;
    address immutable private paraswap;
    address immutable private oneInch;

    constructor(address _wnative, address _zeroEx, address _paraswap, address _oneInch) {
        wnative = _wnative;
        zeroEx = _zeroEx;
        paraswap = _paraswap;
        oneInch = _oneInch;
        swaaplabs = msg.sender;
    }

    modifier _whenNotPaused() {
        _require(!paused, ProxyErr.PAUSED_PROXY);
        _;
    }

    modifier _onlySwaapLabs() {
        _require(msg.sender == swaaplabs, ProxyErr.NOT_SWAAPLABS);
        _;
    }

    /**
    * @notice Pause the proxy
    * @dev Pause disables all of the proxy's functionalities
    */
    function pauseProxy() 
    external
    _onlySwaapLabs
    {
        paused = true;
        emit LOG_PAUSED_PROXY();
    }

    /**
    * @notice Resume the factory's pools
    * @dev Unpausing re-enables all the proxy's functionalities
    */
    function resumeProxy()
    external 
    _onlySwaapLabs
    {
        paused = false;
        emit LOG_UNPAUSED_PROXY();
    }

    /**
    * @notice Allows an owner to begin transferring ownership to a new address,
    * pending.
    * @param _to The new pending owner's address
    */
    function transferOwnership(address _to)
    external
    _onlySwaapLabs
    {
        pendingSwaaplabs = _to;
        emit LOG_TRANSFER_REQUESTED(msg.sender, _to);
    }

    /**
    * @notice Allows an ownership transfer to be completed by the recipient.
    */
    function acceptOwnership()
    external
    {
        _require(msg.sender == pendingSwaaplabs, ProxyErr.NOT_PENDING_SWAAPLABS);

        address oldOwner = swaaplabs;
        swaaplabs = msg.sender;
        pendingSwaaplabs = address(0);

        emit LOG_NEW_SWAAPLABS(oldOwner, msg.sender);
    }

    function getSwaaplabs()
    external
    view
    returns (address)
    {
        return swaaplabs;
    }

    /**
    * @notice Swap the same tokenIn/tokenOut pair from multiple pools given the amount of tokenIn on each swap
    * @dev totalAmountIn should be equal to the sum of tokenAmountIn on each swap
    * @param swaps Array of swaps
    * @param tokenIn Address of tokenIn
    * @param tokenOut Address of tokenOut
    * @param totalAmountIn Maximum amount of tokenIn that the user is willing to trade
    * @param minTotalAmountOut Minimum amount of tokenOut that the user wants to receive
    * @param deadline Maximum deadline for accepting the trade
    * @return totalAmountOut Total amount of tokenOut received
    */
    function batchSwapExactIn(
        ProxyStruct.Swap[] memory swaps,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        uint256 deadline
    )
    external payable
    _beforeDeadline(deadline)
    _whenNotPaused
    _lock
    returns (uint256 totalAmountOut)
    {
        transferFromAll(tokenIn, totalAmountIn);

        for (uint256 i; i < swaps.length;) {
            ProxyStruct.Swap memory swap = swaps[i];

            IERC20 swapTokenIn = IERC20(swap.tokenIn);
            IPool pool = IPool(swap.pool);

            getApproval(swapTokenIn, swap.pool, swap.swapAmount);

            (uint256 tokenAmountOut,) = pool.swapExactAmountInMMM(
                swap.tokenIn,
                swap.swapAmount,
                swap.tokenOut,
                swap.limitAmount,
                swap.maxPrice
            );
            
            totalAmountOut += tokenAmountOut;
                
            unchecked{++i;}
        }

        _require(totalAmountOut >= minTotalAmountOut, ProxyErr.LIMIT_OUT);

        transferAll(tokenOut, totalAmountOut);
        transferAll(tokenIn, getBalance(tokenIn));
    }


    /**
    * @notice Swap the same tokenIn/tokenOut pair from multiple pools given the amount of tokenOut on each swap
    * @param swaps Array of swaps
    * @param tokenIn Address of tokenIn
    * @param tokenOut Address of tokenOut
    * @param totalAmountIn Maximum amount of tokenIn that the user is willing to trade
    * @param deadline Maximum deadline for accepting the trade
    * @return totalAmountIn Total amount of traded tokenIn
    */
    function batchSwapExactOut(
        ProxyStruct.Swap[] memory swaps,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn,
        uint256 deadline
    )
    external payable
    _beforeDeadline(deadline)
    _whenNotPaused
    _lock
    returns (uint256 totalAmountIn)
    {
        transferFromAll(tokenIn, maxTotalAmountIn);

        for (uint256 i; i < swaps.length;) {
            ProxyStruct.Swap memory swap = swaps[i];

            IERC20 swapTokenIn = IERC20(swap.tokenIn);
            IPool pool = IPool(swap.pool);

            getApproval(swapTokenIn, swap.pool, swap.limitAmount);

            (uint256 tokenAmountIn,) = pool.swapExactAmountOutMMM(
                swap.tokenIn,
                swap.limitAmount,
                swap.tokenOut,
                swap.swapAmount,
                swap.maxPrice
            );

            totalAmountIn += tokenAmountIn;
            unchecked{++i;}
        }

        _require(totalAmountIn <= maxTotalAmountIn, ProxyErr.LIMIT_IN);

        transferAll(tokenOut, getBalance(tokenOut));
        transferAll(tokenIn, getBalance(tokenIn));
    }


    /**
    * @notice Performs multiple swapSequences given the amount of tokenIn on each swap 
    * @dev Few considerations: 
    * - swapSequences[i][j]:
    *   a) i: represents a swap sequence (swapSequences[i]   : tokenIn --> B --> C --> tokenOut)
    *   b) j: represents a swap          (swapSequences[i][0]: tokenIn --> B)
    * - rows 'i' could be of varying lengths for ex:
    * - swapSequences = {swapSequence 1: tokenIn --> B --> C --> tokenOut,
    *                    swapSequence 2: tokenIn --> tokenOut}
    * - each swap sequence should have the same starting tokenIn and finishing tokenOut
    * - totalAmountIn should be equal to the sum of tokenAmountIn on each swapSequence
    * @param swapSequences Array of swapSequences
    * @param tokenIn Address of tokenIn
    * @param tokenOut Address of tokenOut
    * @param totalAmountIn Maximum amount of tokenIn that the user is willing to trade
    * @param minTotalAmountOut Minimum amount of tokenOut that the user must receive
    * @param deadline Maximum deadline for accepting the trade
    * @return totalAmountOut Total amount of tokenOut received
    */
    function multihopBatchSwapExactIn(
        ProxyStruct.Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        uint256 deadline
    )
    external payable
    _beforeDeadline(deadline)
    _whenNotPaused
    _lock
    returns (uint256 totalAmountOut)
    {

        transferFromAll(tokenIn, totalAmountIn);

        for (uint256 i; i < swapSequences.length;) {
            uint256 tokenAmountOut;
            for (uint256 j; j < swapSequences[i].length;) {
                ProxyStruct.Swap memory swap = swapSequences[i][j];

                IERC20 swapTokenIn = IERC20(swap.tokenIn);
                if (j >= 1) {
                    // Makes sure that on the second swap the output of the first was used
                    // so there is not intermediate token leftover
                    swap.swapAmount = tokenAmountOut;
                }
                IPool pool = IPool(swap.pool);

                getApproval(swapTokenIn, swap.pool, swap.swapAmount);

                (tokenAmountOut,) = pool.swapExactAmountInMMM(
                    swap.tokenIn,
                    swap.swapAmount,
                    swap.tokenOut,
                    swap.limitAmount,
                    swap.maxPrice
                );
                unchecked{++j;}
            }
            // This takes the amountOut of the last swap
            totalAmountOut += tokenAmountOut;
            unchecked{++i;}
        }

        _require(totalAmountOut >= minTotalAmountOut, ProxyErr.LIMIT_OUT);

        transferAll(tokenOut, totalAmountOut);
        transferAll(tokenIn, getBalance(tokenIn));

    }

    /**
    * @notice Performs multiple swapSequences given the amount of tokenOut on each swapSequence 
    * @dev Few considerations: 
    * - swapSequences[i][j]:
    *   a) i: represents a swap sequence (swapSequences[i]   : tokenIn --> B --> tokenOut)
    *   b) j: represents a swap          (swapSequences[i][0]: tokenIn --> B)
    * - rows 'i' could be of varying lengths for ex:
    * - swapSequences = {swapSequence 1: tokenIn --> B --> tokenOut,
    *                    swapSequence 2: tokenIn --> tokenOut}
    * - each swap sequence should have the same starting tokenIn and finishing tokenOut
    * - maxTotalAmountIn can be differennt than the sum of tokenAmountIn on each swapSequence
    * - totalAmountOut is equal to the sum of the amount of tokenOut on each swap sequence
    * - /!\ /!\ a swap sequence should have 1 multihop at most (swapSequences[i].length <= 2) /!\ /!\
    * @param swapSequences Array of swapSequences
    * @param tokenIn Address of tokenIn
    * @param tokenOut Address of tokenOut
    * @param maxTotalAmountIn Maximum amount of tokenIn that the user is willing to trade
    * @param deadline Maximum deadline for accepting the trade
    * @return totalAmountIn Total amount of traded tokenIn
    */
    function multihopBatchSwapExactOut(
        ProxyStruct.Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn,
        uint256 deadline
    )
    external payable
    _beforeDeadline(deadline)
    _whenNotPaused
    _lock
    returns (uint256 totalAmountIn)
    {
        transferFromAll(tokenIn, maxTotalAmountIn);

        for (uint256 i; i < swapSequences.length;) {
            uint256 tokenAmountInFirstSwap;
            // Specific code for a simple swap and a multihop (2 swaps in sequence)

            if (swapSequences[i].length == 1) {
                ProxyStruct.Swap memory swap = swapSequences[i][0];
                IERC20 swapTokenIn = IERC20(swap.tokenIn);

                IPool pool = IPool(swap.pool);

                getApproval(swapTokenIn, swap.pool, swap.limitAmount);

                (tokenAmountInFirstSwap,) = pool.swapExactAmountOutMMM(
                    swap.tokenIn,
                    swap.limitAmount,
                    swap.tokenOut,
                    swap.swapAmount,
                    swap.maxPrice
                );
            } else {
                // Consider we are swapping A -> B and B -> C. The goal is to buy a given amount
                // of token C. But first we need to buy B with A so we can then buy C with B
                // To get the exact amount of C we then first need to calculate how much B we'll need:
                ProxyStruct.Swap memory firstSwap = swapSequences[i][0];
                ProxyStruct.Swap memory secondSwap = swapSequences[i][1];

                IPool poolSecondSwap = IPool(secondSwap.pool);
                IPool poolFirstSwap = IPool(firstSwap.pool);
                (Struct.SwapResult memory secondSwapResult, ) = poolSecondSwap.getAmountInGivenOutMMM(
                    secondSwap.tokenIn,
                    secondSwap.limitAmount,
                    secondSwap.tokenOut,
                    secondSwap.swapAmount,
                    secondSwap.maxPrice
                );
                // This would be token B as described above
                uint256 intermediateTokenAmount = secondSwapResult.amount;
                (Struct.SwapResult memory firstSwapResult, ) = poolFirstSwap.getAmountInGivenOutMMM(
                    firstSwap.tokenIn,
                    firstSwap.limitAmount,
                    firstSwap.tokenOut,
                    intermediateTokenAmount,
                    firstSwap.maxPrice
                );
                tokenAmountInFirstSwap = firstSwapResult.amount;
                _require(tokenAmountInFirstSwap <= firstSwap.limitAmount, ProxyErr.LIMIT_IN);

                // Buy intermediateTokenAmount of token B with A in the first pool
                IERC20 firstSwapTokenIn = IERC20(firstSwap.tokenIn);

                getApproval(firstSwapTokenIn, firstSwap.pool, tokenAmountInFirstSwap);

                poolFirstSwap.swapExactAmountOutMMM(
                    firstSwap.tokenIn,
                    tokenAmountInFirstSwap,
                    firstSwap.tokenOut,
                    intermediateTokenAmount, // This is the amount of token B we need
                    firstSwap.maxPrice
                );

                // Buy the final amount of token C desired
                IERC20 secondSwapTokenIn = IERC20(secondSwap.tokenIn);

                getApproval(secondSwapTokenIn, secondSwap.pool, intermediateTokenAmount);

                poolSecondSwap.swapExactAmountOutMMM(
                    secondSwap.tokenIn,
                    intermediateTokenAmount,
                    secondSwap.tokenOut,
                    secondSwap.swapAmount,
                    secondSwap.maxPrice
                );
            }
            totalAmountIn += tokenAmountInFirstSwap;
            unchecked{++i;}
        }

        _require(totalAmountIn <= maxTotalAmountIn, ProxyErr.LIMIT_IN);

        transferAll(tokenOut, getBalance(tokenOut));
        transferAll(tokenIn, getBalance(tokenIn));
    }

    /**
    * @notice Creates a balanced pool with customized parameters where oracle-spot-price == pool-spot-price
    * @dev A pool is balanced if (balanceI * weight_j) / (balance_j * weight_i) = oraclePrice_j / oraclePrice_i, for all i != j
    * as a result: balanceI = (oraclePrice_j * balance_j * weight_i) / (oraclePrice_i * weight_j)
    * @param bindTokens Array containing the information of the tokens to bind [tokenAddress, balance, weight, oracleAddress]
    * @param params Customized parameters of the pool 
    * @param finalize Bool to finalize the pool or not
    * @param deadline Maximum deadline for accepting the creation of the pool
    * @return poolAddress The created pool's address
    */
    function createBalancedPoolWithParams(
	    ProxyStruct.BindToken[] memory bindTokens,
        ProxyStruct.Params calldata params,
        IFactory factory,
        bool finalize,
        uint256 deadline
    ) 
    external payable
    _beforeDeadline(deadline)
    _whenNotPaused
    _lock
    returns (address poolAddress)
    {
        uint256 bindTokensNumber = bindTokens.length;
        uint256[] memory oraclePrices = new uint256[](bindTokensNumber);
        int256 price;
        for(uint256 i; i < bindTokensNumber;) {
            (,price,,,) = AggregatorV3Interface(bindTokens[i].oracle).latestRoundData();
            _require(price > 0, ProxyErr.NEGATIVE_PRICE);
            oraclePrices[i] = uint(price);
            unchecked {++i;}
        }

        uint256 balanceI;
        uint8 decimals0 = AggregatorV3Interface(bindTokens[0].oracle).decimals() + IERC20WithDecimals(bindTokens[0].token).decimals();
        for(uint256 i=1; i < bindTokensNumber;){
            //    balanceI = (oraclePrice_j / oraclePrice_i) * (balance_j * weight_i) / (weight_j)
            // => balanceI = (relativePrice_j_i * balance_j * weight_i) / (weight_j)
            balanceI = getTokenRelativePrice(
                oraclePrices[i],
                AggregatorV3Interface(bindTokens[i].oracle).decimals() + IERC20WithDecimals(bindTokens[i].token).decimals(),
                oraclePrices[0],
                decimals0
            );
            
            balanceI = mul(balanceI, bindTokens[0].balance);
            balanceI = mul(balanceI, bindTokens[i].weight);
            balanceI = div(balanceI, bindTokens[0].weight);
            _require(balanceI <= bindTokens[i].balance, ProxyErr.LIMIT_IN);
            bindTokens[i].balance = balanceI;
            unchecked {++i;}
        }
    

        poolAddress = _createPoolWithParams(
            bindTokens,
            params,
            factory,
            finalize
        );

    }

    /**
    * @notice Creates a pool with customized parameters
    * @param bindTokens Array containing the information of the tokens to bind [tokenAddress, balance, weight, oracleAddress]
    * @param params Customized parameters of the pool 
    * @param finalize Bool to finalize the pool or not
    * @param deadline Maximum deadline for accepting the creation of the pool
    * @return poolAddress The created pool's address
    */
    function createPoolWithParams(
	    ProxyStruct.BindToken[] calldata bindTokens,
        ProxyStruct.Params calldata params,
        IFactory factory,
        bool finalize,
        uint256 deadline
    )
    external payable
    _beforeDeadline(deadline)
    _whenNotPaused
    _lock
    returns (address poolAddress)
    {
        poolAddress = _createPoolWithParams(
                bindTokens,
                params,
                factory,
                finalize
        );
    }

    function _createPoolWithParams(
	    ProxyStruct.BindToken[] memory bindTokens,
        ProxyStruct.Params calldata params,
        IFactory factory,
        bool finalize
    ) 
        internal
        returns (address poolAddress)
    {
        poolAddress = factory.newPool();
        IPool pool = IPool(poolAddress);
        
        // setting the pool's parameters
        pool.setPublicSwap(params.publicSwap);
        pool.setSwapFee(params.swapFee);
        pool.setPriceStatisticsLookbackInRound(params.priceStatisticsLookbackInRound);
        pool.setDynamicCoverageFeesZ(params.dynamicCoverageFeesZ);
        pool.setDynamicCoverageFeesHorizon(params.dynamicCoverageFeesHorizon);
        pool.setPriceStatisticsLookbackInSec(params.priceStatisticsLookbackInSec);

        _setPool(poolAddress, bindTokens, finalize);
    }

    /**
    * @notice Creates a pool with default parameters
    * @param bindTokens Array containing the information of the tokens to bind [tokenAddress, balance, weight, oracleAddress]
    * @param finalize Bool to finalize the pool or not
    * @param deadline Maximum deadline for accepting the creation of the pool
    * @return poolAddress The created pool's address
    */
    function createPool(
	    ProxyStruct.BindToken[] calldata bindTokens,
        IFactory factory,
        bool finalize,
        uint256 deadline
    ) 
    external payable
    _beforeDeadline(deadline)
    _whenNotPaused
    _lock
    returns (address poolAddress)
    {
        poolAddress = factory.newPool();

        _setPool(poolAddress, bindTokens, finalize);
    }

    function _setPool(
        address pool,
	    ProxyStruct.BindToken[] memory bindTokens,
        bool finalize
    )
        internal
    {
        address tokenIn;

        for (uint256 i; i < bindTokens.length;) {
            ProxyStruct.BindToken memory bindToken = bindTokens[i];

            transferFromAll(bindToken.token, bindToken.balance);
            
            if(isNative(bindToken.token)) {
                tokenIn = wnative;
            }
            else {
                tokenIn = bindToken.token;
            }

            getApproval(IERC20(tokenIn), pool, bindToken.balance);
            
            IPool(pool).bindMMM(tokenIn, bindToken.balance, bindToken.weight, bindToken.oracle);
            
            transferAll(bindToken.token, getBalance(bindToken.token));

            unchecked{++i;}
        }

        if (finalize) {
            // This will finalize the pool and send the pool shares to the caller
            IPool(pool).finalize();
            IERC20(pool).transfer(msg.sender, IERC20(pool).balanceOf(address(this)));
        }

        /*
        NOTES:
            If we add "require(!finalized && no bound tokens)" for Pool.setControllerAndTransfer(address manager)
            The proxy cannot transfer the controller to the msg.sender
            In that case we should either set the controller in pool.finalize(msg.sender)
            Or use Auth like in BActions' proxy
        */ 
        IPool(pool).setControllerAndTransfer(msg.sender);
    }

    /**
    * @notice Joins the pool after externally trading an input token with the necessary tokens for the pool
    * @dev The bindedTokens and maxAmountsIn should be in the same order of the output of pool.getTokens()
    * @dev when joining the pool using the native token, the wrapped address should be specified on 0x's API
    * @param bindedTokens The addresses of the binded tokens to the pool
    * @param maxAmountsIn The maximum amount of tokens that can be used to join the pool
    * @param fillQuotes The trades needed before joining the pool (uses 0x's API)
    * @param joiningAsset The address of the input token
    * @param joiningAmount The amount of the input token
    * @param pool The pool's address
    * @param poolAmountOut The amount of pool shares expected to be received
    * @param deadline Maximum deadline for accepting the joinswapExternAmountIn
    * @return poolAmountOut The amount of pool shares received
    */
    function joinPoolVia0x(
        address[] calldata bindedTokens,
        uint256[] memory maxAmountsIn,
        ZeroExStruct.Quote[] calldata fillQuotes,
        address joiningAsset,
        uint256 joiningAmount,
        address pool,
        uint256 poolAmountOut,
        uint256 deadline
    )
    external payable
    _beforeDeadline(deadline)
    _whenNotPaused
    _lock
    returns (uint256)
    {
        transferFromAll(joiningAsset, joiningAmount);
        
        tradeAssetsZeroEx(fillQuotes, joiningAsset);

        poolAmountOut = getMaximumPoolShares(bindedTokens, maxAmountsIn, pool, poolAmountOut);

        IPool(pool).joinPool(poolAmountOut, maxAmountsIn);

        for (uint256 i; i < bindedTokens.length;) {
            transferAll(bindedTokens[i], getBalance(bindedTokens[i]));
            unchecked {++i;}
        }

        // Each quote represents a unique ERC20 used for joining the pool
        // If the number of quotes is equal to the number of binded token to the pool
        // --> the joining asset is not in the pool and the function should transfer
        // any leftover asset from trading
        if(fillQuotes.length == bindedTokens.length ) {
            transferAll(joiningAsset, getBalance(joiningAsset));
        }

        IERC20(pool).transfer(msg.sender, poolAmountOut);
        
        return poolAmountOut;
    }

    function tradeAssetsZeroEx(
        ZeroExStruct.Quote[] calldata fillQuotes,
        address joiningAsset
    ) internal {

        address tradedToken = isNative(joiningAsset)? wnative : joiningAsset;
    
        for(uint256 i; i < fillQuotes.length;) {           

            getApproval(IERC20(tradedToken), fillQuotes[i].spender, fillQuotes[i].sellAmount);

            // Call the encoded swap function call on the contract at `swapTarget`
            (bool success,) = zeroEx.call(fillQuotes[i].swapCallData);
            _require(success, ProxyErr.FAILED_CALL);
            
            _require(getBalance(fillQuotes[i].buyToken) >= fillQuotes[i].guaranteedAmountOut, ProxyErr.LIMIT_OUT);

            unchecked{++i;}
        }
    }

    /**
    * @notice Performs a swap using 0x, paraswap or 1inch's sdk
    * @param tokenIn The address of tokenIn
    * @param amountIn The maximum amount of tokenIn
    * @param tokenOut The address of tokenOut
    * @param amountOut The minimum expected amount of tokenOut
    * @param spender The SC's address that will spender the input token
    * @param swapCallData The swap call data
    */
    function externalSwap(
        IERC20 tokenIn,
        uint256 amountIn,
        IERC20 tokenOut,
        uint256 amountOut,
        address spender,
        Aggregator aggregator,
        bytes calldata swapCallData,
        uint256 deadline
    )
    external
    _beforeDeadline(deadline)
    _whenNotPaused
    _lock
    {
        
        tokenIn.safeTransferFrom(msg.sender, address(this), amountIn);

        getApproval(tokenIn, spender, amountIn);

        // Call the encoded swap function call on the contract at `swapTarget`
        bool success;
        if (aggregator == Aggregator.ZeroEx) {
            (success,) = zeroEx.call(swapCallData);
        } else if (aggregator == Aggregator.Paraswap) {
            (success,) = paraswap.call(swapCallData);
        } else if (aggregator == Aggregator.OneInch) {
            (success,) = oneInch.call(swapCallData);
        }

        _require(success, ProxyErr.FAILED_CALL);
        
        if(address(tokenOut) != NATIVE_ADDRESS) {
            uint256 receivedAmountOut = tokenOut.balanceOf(address(this));
            _require(receivedAmountOut >= amountOut, ProxyErr.LIMIT_OUT);
            tokenOut.safeTransfer(msg.sender, receivedAmountOut);
        } else {
            uint256 receivedAmountOut = address(this).balance;
            _require(receivedAmountOut >= amountOut, ProxyErr.LIMIT_OUT);
            payable(msg.sender).transfer(receivedAmountOut);
        }

        tokenIn.safeTransfer(msg.sender, tokenIn.balanceOf(address(this)));

    }

    function getMaximumPoolShares(
        address[] calldata bindedTokens, // must be in the same order as the Pool
        uint256[] memory maxAmountsIn,
        address pool,
        uint256 poolAmountOut
    ) internal 
    returns (uint256)
    {

        uint256 ratio = type(uint256).max;

        for(uint256 i; i < bindedTokens.length;) {
            uint256 tokenBalance = IERC20(bindedTokens[i]).balanceOf(address(this));
            uint256 _ratio = divTruncated(tokenBalance, IPool(pool).getBalance(bindedTokens[i]));
            if(_ratio < ratio) {
                ratio  = _ratio;
            }
            unchecked {++i;}
        }

        uint256 extractablePoolShares = mulTruncated(ratio, IPool(pool).totalSupply());
        uint256 sharesRatio = div(extractablePoolShares, poolAmountOut);

        for(uint256 i; i < bindedTokens.length;) {
            maxAmountsIn[i] = mul(maxAmountsIn[i], sharesRatio);
            getApproval(IERC20(bindedTokens[i]), pool, maxAmountsIn[i]);
            unchecked {++i;}
        }

        return extractablePoolShares;

    }

    /**
    * @notice Join a pool with a fixed poolAmountOut
    * @dev Joining a pool could be done using the native token or its wrapped token, but not with both at the same time. 
    * In both cases, the wrapped token's address should be specified as an input (tokenIn).
    * @param pool Pool's address
    * @param poolAmountOut Pool tokens (shares) to be receives
    * @param maxAmountsIn Maximum amounts of each token
    * @param deadline Maximum deadline for accepting the joinPool
    */
    function joinPool(
        address pool,
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn,
        uint256 deadline
    )
    external payable
    _beforeDeadline(deadline)
    _whenNotPaused
    _lock
    {

        address[] memory tokensIn = IPool(pool).getTokens();

        for(uint256 i; i < tokensIn.length;) {

            if(tokensIn[i] == wnative && msg.value > 0) {
                _require(msg.value == maxAmountsIn[i], ProxyErr.BAD_LIMIT_IN);
                transferFromAll(NATIVE_ADDRESS, maxAmountsIn[i]);
            } else {
                transferFromAll(tokensIn[i], maxAmountsIn[i]);
            }

            getApproval(IERC20(tokensIn[i]), pool, maxAmountsIn[i]);

            unchecked{++i;}
        }

        IPool(pool).joinPool(poolAmountOut, maxAmountsIn);

        for(uint256 i; i < tokensIn.length;) {

            if(tokensIn[i] == wnative && msg.value > 0) {
                transferAll(NATIVE_ADDRESS, IERC20(tokensIn[i]).balanceOf(address(this)));
            } else {
                transferAll(tokensIn[i], IERC20(tokensIn[i]).balanceOf(address(this)));
            }

            unchecked{++i;}
        }

        IERC20(pool).transfer(msg.sender, poolAmountOut);

    }

    /**
    * @notice Joins a pool with 1 tokenIn
    * @dev When joining a with the native token, msg.value should be equal to tokenAmountIn
    * @param pool Pool's address
    * @param tokenIn TokenIn's address
    * @param tokenAmountIn Amount of token In
    * @param minPoolAmountOut Minimum pool tokens (shares) expected to receive
    * @param deadline Maximum deadline for accepting the joinswapExternAmountIn
    * @return poolAmountOut The pool tokens received
    */
    function joinswapExternAmountIn(
        address pool,
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut,
        uint256 deadline
    )
    external payable
    _beforeDeadline(deadline)
    _whenNotPaused
    _lock
    returns (uint256 poolAmountOut)
    {
        transferFromAll(tokenIn, tokenAmountIn);

        if(tokenIn == NATIVE_ADDRESS) {
            _require(msg.value == tokenAmountIn, ProxyErr.BAD_LIMIT_IN);
            tokenIn = wnative;
        }
        
        getApproval(IERC20(tokenIn), pool, tokenAmountIn);

        poolAmountOut = IPool(pool).joinswapExternAmountInMMM(tokenIn, tokenAmountIn, minPoolAmountOut);
        
        IERC20(pool).transfer(msg.sender, poolAmountOut);
        
        return poolAmountOut;
    }

    function transferFromAll(address token, uint256 amount) internal {
        if (isNative(token)) {
            // The 'amount' input is not used in the payable case in order to convert all the
            // native token to wrapped native token. This is useful in function transferAll where only 
            // one transfer is needed when a fraction of the wrapped tokens are used.
            IWrappedERC20(wnative).deposit{value: msg.value}();
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function getApproval(IERC20 token, address target, uint256 amount) internal {
        
        // required for some ERC20 such as USDT before changing the allowed transferable tokens
        // https://github.com/d-xo/weird-erc20
        if (token.allowance(address(this), target) < amount) {
            token.safeApprove(target, 0);
            token.safeApprove(target, type(uint256).max);
        }

    }

    function getBalance(address token) internal view returns (uint256) {
        if (isNative(token)) {
            return IWrappedERC20(wnative).balanceOf(address(this));
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    function transferAll(address token, uint256 amount) internal {
        if (amount != 0) {
            if (isNative(token)) {
                IWrappedERC20(wnative).withdraw(amount);
                payable(msg.sender).transfer(amount);
            } else {
                IERC20(token).safeTransfer(msg.sender, amount);
            }
        }
    }

    function isNative(address token) internal pure returns(bool) {
        return (token == NATIVE_ADDRESS);
    }

    receive() external payable{}

    function mul(uint256 a, uint256 b)
        internal pure
        returns (uint256)
    {
        uint256 c0 = a * b;
        uint256 c1 = c0 + (ONE / 2);
        uint256 c2 = c1 / ONE;
        return c2;
    }

    function mulTruncated(uint256 a, uint256 b)
    internal pure
    returns (uint256)
    {
        uint256 c0 = a * b;
        return c0 / ONE;
    }

    function div(uint256 a, uint256 b)
        internal pure
        returns (uint256)
    {
        uint256 c0 = a * ONE;
        uint256 c1 = c0 + (b / 2);
        uint256 c2 = c1 / b;
        return c2;
    }

    function divTruncated(uint256 a, uint256 b)
    internal pure
    returns (uint256)
    {
        uint256 c0 = a * ONE;
        return c0 / b;
    }

    function getTokenRelativePrice(
        uint256 price1, uint8 decimal1,
        uint256 price2, uint8 decimal2
    )
    internal
    pure
    returns (uint256) {
        // we consider tokens price to be > 0
        uint256 rawDiv = div(price2, price1);
        if (decimal1 == decimal2) {
            return rawDiv;
        } else if (decimal1 > decimal2) {
            return mul(
                rawDiv,
                10**(decimal1 - decimal2)*ONE
            );
        } else {
            return div(
                rawDiv,
                10**(decimal2 - decimal1)*ONE
            );
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

/**
 * @author Forked from contracts developed by Balancer Labs and adapted by Swaap Labs
*/
library ProxyErr {

    uint256 internal constant REENTRY               = 0;
    uint256 internal constant PASSED_DEADLINE       = 1;
    uint256 internal constant LIMIT_IN              = 2;
    uint256 internal constant LIMIT_OUT             = 3;
    uint256 internal constant BAD_LIMIT_IN          = 4;
    uint256 internal constant NEGATIVE_PRICE        = 5;
    uint256 internal constant FAILED_CALL           = 6;
    uint256 internal constant NOT_SWAAPLABS         = 7;
    uint256 internal constant NOT_PENDING_SWAAPLABS = 8;
    uint256 internal constant PAUSED_PROXY          = 9;
}

/**
* @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 99 are
* supported.
*/
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}


/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 99 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert uint256 based on the error code, with the following format:
    // 'PROOXY#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 00 to 99).
    //
    // We don't have revert uint256s embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual uint256 characters.
    //
    // The dynamic uint256 creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-99
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full uint256. The PROOXY# part is a known constant
        // (0x50524f4f585923): we simply shift this by 16 (to provide space for the 2 bytes of the error code), and add
        // the characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 184 bits (256 minus the length of the uint256, 9 characters * 8
        // bits per character = 72) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(184, add(0x50524f4f5859230000, add(units, shl(8, tenths))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ uint256 location offset ] [ uint256 length ] [ uint256 contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(uint256) function. We
        // also write zeroes to the next 29 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the uint256, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The uint256 length is fixed: 8 characters.
        mstore(0x24, 9)
        // Finally, the uint256 itself is stored.
        mstore(0x44, revertReason)

        // Even if the uint256 is only 8 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

contract ProxyStruct {
    struct Pool {
        address pool;
        uint256 tokenBalanceIn;
        uint256 tokenWeightIn;
        uint256 tokenBalanceOut;
        uint256 tokenWeightOut;
        uint256 swapFee;
        uint256 effectiveLiquidity;
    }

    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount; // tokenInAmount / tokenOutAmount
        uint256 limitAmount; // minAmountOut / maxAmountIn
        uint256 maxPrice;
    }

    struct Params {
        bool    publicSwap;
        uint256 swapFee;
        uint8   priceStatisticsLookbackInRound;
        uint64  dynamicCoverageFeesZ;
        uint256 dynamicCoverageFeesHorizon;
        uint256 priceStatisticsLookbackInSec;
    }

    struct BindToken {
        address token;
        uint256 balance;
        uint80  weight;
        address oracle;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

interface IProxyOwner {
    
    /**
    * @notice Emitted when the proxy is paused 
    */
    event LOG_PAUSED_PROXY();

    /**
    * @notice Emitted when the proxy is unpaused 
    */
    event LOG_UNPAUSED_PROXY();

    /**
    * @notice Emitted when a Swaap labs transfer is requested
    * @param from The current Swaap labs address
    * @param to The pending new Swaap labs address
    */
    event LOG_TRANSFER_REQUESTED(
        address indexed from,
        address indexed to
    );

    /**
    * @notice Emitted when a new address accepts the Swaap labs role
    * @param from The old Swaap labs address
    * @param to The new Swaap labs address
    */
    event LOG_NEW_SWAAPLABS(
        address indexed from,
        address indexed to
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

contract ZeroExStruct {
    struct Quote {
        // The `sellAmount` field from the API response.
        uint256 sellAmount;
        // The `buyTokenAddress` field from the API response.
        address buyToken;
        // The `guaranteedPrice` * `sellAmount` fields from the API response. 
        uint256 guaranteedAmountOut;
        // The `allowanceTarget` field from the API response.
        address spender;
        // The `data` field from the API response.
        bytes swapCallData;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

import "../structs/ProxyStruct.sol";
import "../structs/ZeroExStruct.sol";

import "@swaap-labs/swaap-core-v1/contracts/structs/Struct.sol";

import "@swaap-labs/swaap-core-v1/contracts/interfaces/IFactory.sol";

interface IProxy {

    /**
    * @notice Swap the same tokenIn/tokenOut pair from multiple pools given the amount of tokenIn on each swap
    * @dev totalAmountIn should be equal to the sum of tokenAmountIn on each swap
    * @param swaps Array of swaps
    * @param tokenIn Address of tokenIn
    * @param tokenOut Address of tokenOut
    * @param totalAmountIn Maximum amount of tokenIn that the user is willing to trade
    * @param minTotalAmountOut Minimum amount of tokenOut that the user wants to receive
    * @param deadline Maximum deadline for accepting the trade
    * @return totalAmountOut Total amount of tokenOut received
    */
    function batchSwapExactIn(
        ProxyStruct.Swap[] memory swaps,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        uint256 deadline
    )
    external payable
    returns (uint256 totalAmountOut);

    /**
    * @notice Swap the same tokenIn/tokenOut pair from multiple pools given the amount of tokenOut on each swap
    * @param swaps Array of swaps
    * @param tokenIn Address of tokenIn
    * @param tokenOut Address of tokenOut
    * @param totalAmountIn Maximum amount of tokenIn that the user is willing to trade
    * @param deadline Maximum deadline for accepting the trade
    * @return totalAmountIn Total amount of traded tokenIn
    */
    function batchSwapExactOut(
        ProxyStruct.Swap[] memory swaps,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn,
        uint256 deadline
    )
    external payable
    returns (uint256 totalAmountIn);

        /**
    * @notice Performs multiple swapSequences given the amount of tokenIn on each swap 
    * @dev Few considerations: 
    * - swapSequences[i][j]:
    *   a) i: represents a swap sequence (swapSequences[i]   : tokenIn --> B --> C --> tokenOut)
    *   b) j: represents a swap          (swapSequences[i][0]: tokenIn --> B)
    * - rows 'i' could be of varying lengths for ex:
    * - swapSequences = {swapSequence 1: tokenIn --> B --> C --> tokenOut,
    *                    swapSequence 2: tokenIn --> tokenOut}
    * - each swap sequence should have the same starting tokenIn and finishing tokenOut
    * - totalAmountIn should be equal to the sum of tokenAmountIn on each swapSequence
    * @param swapSequences Array of swapSequences
    * @param tokenIn Address of tokenIn
    * @param tokenOut Address of tokenOut
    * @param totalAmountIn Maximum amount of tokenIn that the user is willing to trade
    * @param minTotalAmountOut Minimum amount of tokenOut that the user must receive
    * @param deadline Maximum deadline for accepting the trade
    * @return totalAmountOut Total amount of tokenOut received
    */
    function multihopBatchSwapExactIn(
        ProxyStruct.Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        uint256 deadline
    )
    external payable
    returns (uint256 totalAmountOut);

        /**
    * @notice Performs multiple swapSequences given the amount of tokenOut on each swapSequence 
    * @dev Few considerations: 
    * - swapSequences[i][j]:
    *   a) i: represents a swap sequence (swapSequences[i]   : tokenIn --> B --> tokenOut)
    *   b) j: represents a swap          (swapSequences[i][0]: tokenIn --> B)
    * - rows 'i' could be of varying lengths for ex:
    * - swapSequences = {swapSequence 1: tokenIn --> B --> tokenOut,
    *                    swapSequence 2: tokenIn --> tokenOut}
    * - each swap sequence should have the same starting tokenIn and finishing tokenOut
    * - maxTotalAmountIn can be differennt than the sum of tokenAmountIn on each swapSequence
    * - totalAmountOut is equal to the sum of the amount of tokenOut on each swap sequence
    * - /!\ /!\ a swap sequence should have 1 multihop at most (swapSequences[i].length <= 2) /!\ /!\
    * @param swapSequences Array of swapSequences
    * @param tokenIn Address of tokenIn
    * @param tokenOut Address of tokenOut
    * @param maxTotalAmountIn Maximum amount of tokenIn that the user is willing to trade
    * @param deadline Maximum deadline for accepting the trade
    * @return totalAmountIn Total amount of traded tokenIn
    */
    function multihopBatchSwapExactOut(
        ProxyStruct.Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn,
        uint256 deadline
    )
    external payable
    returns (uint256 totalAmountIn);


    /**
    * @notice Creates a balanced pool with customized parameters where oracle-spot-price == pool-spot-price
    * @dev A pool is balanced if (balanceI * weight_j) / (balance_j * weight_i) = oraclePrice_j / oraclePrice_i, for all i != j
    * as a result: balanceI = (oraclePrice_j * balance_j * weight_i) / (oraclePrice_i * weight_j)
    * @param bindTokens Array containing the information of the tokens to bind [tokenAddress, balance, weight, oracleAddress]
    * @param params Customized parameters of the pool 
    * @param finalize Bool to finalize the pool or not
    * @param deadline Maximum deadline for accepting the creation of the pool
    * @return poolAddress The created pool's address
    */
    function createBalancedPoolWithParams(
	    ProxyStruct.BindToken[] memory bindTokens,
        ProxyStruct.Params calldata params,
        IFactory factory,
        bool finalize,
        uint256 deadline
    ) 
    external payable
    returns (address poolAddress);


    /**
    * @notice Creates a pool with customized parameters
    * @param bindTokens Array containing the information of the tokens to bind [tokenAddress, balance, weight, oracleAddress]
    * @param params Customized parameters of the pool 
    * @param finalize Bool to finalize the pool or not
    * @param deadline Maximum deadline for accepting the creation of the pool
    * @return poolAddress The created pool's address
    */
    function createPoolWithParams(
	    ProxyStruct.BindToken[] calldata bindTokens,
        ProxyStruct.Params calldata params,
        IFactory factory,
        bool finalize,
        uint256 deadline
    )
    external payable
    returns (address poolAddress);

        /**
    * @notice Creates a pool with default parameters
    * @param bindTokens Array containing the information of the tokens to bind [tokenAddress, balance, weight, oracleAddress]
    * @param finalize Bool to finalize the pool or not
    * @param deadline Maximum deadline for accepting the creation of the pool
    * @return poolAddress The created pool's address
    */
    function createPool(
	    ProxyStruct.BindToken[] calldata bindTokens,
        IFactory factory,
        bool finalize,
        uint256 deadline
    ) 
    external payable
    returns (address poolAddress);

    /**
    * @notice Joins the pool after externally trading an input token with the necessary tokens for the pool
    * @dev The bindedTokens and maxAmountsIn should be in the same order of the output of pool.getTokens()
    * @dev when joining the pool using the native token, the wrapped address should be specified on 0x's API
    * @param bindedTokens The addresses of the binded tokens to the pool
    * @param maxAmountsIn The maximum amount of tokens that can be used to join the pool
    * @param fillQuotes The trades needed before joining the pool (uses 0x's API)
    * @param joiningAsset The address of the input token
    * @param joiningAmount The amount of the input token
    * @param pool The pool's address
    * @param poolAmountOut The amount of pool shares expected to be received
    * @param deadline Maximum deadline for accepting the joinswapExternAmountIn
    * @return poolAmountOut The amount of pool shares received
    */
    function joinPoolVia0x( // swap and join pool
        address[] calldata bindedTokens, // must be in the same order as the Pool
        uint256[] memory maxAmountsIn,
        ZeroExStruct.Quote[] calldata fillQuotes,
        address joiningAsset,
        uint256 joiningAmount,
        address pool,
        uint256 poolAmountOut,
        uint256 deadline
    )
    external payable
    returns (uint256);

    /**
    * @notice Join a pool with a fixed poolAmountOut
    * @dev Joining a pool could be done using the native token or its wrapped token, but not with both at the same time. 
    * In both cases, the wrapped token's address should be specified as an input (tokenIn).
    * @param pool Pool's address
    * @param poolAmountOut Pool tokens (shares) to be receives
    * @param maxAmountsIn Maximum amounts of each token
    * @param deadline Maximum deadline for accepting the joinPool
    */
    function joinPool(
        address pool,
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn,
        uint256 deadline
    )
    external payable;

    /**
    * @notice Joins a pool with 1 tokenIn
    * @dev When joining a with the native token, msg.value should be equal to tokenAmountIn
    * @param pool Pool's address
    * @param tokenIn TokenIn's address
    * @param tokenAmountIn Amount of token In
    * @param minPoolAmountOut Minimum pool tokens (shares) expected to receive
    * @param deadline Maximum deadline for accepting the joinswapExternAmountIn
    * @return poolAmountOut The pool tokens received
    */
    function joinswapExternAmountIn(
        address pool,
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut,
        uint256 deadline
    )
    external payable
    returns (uint256 poolAmountOut);

}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedERC20 is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20WithDecimals is IERC20 {
    function decimals() external view returns(uint8);
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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

/**
* @title The interface for a Swaap V1 Pool Factory
*/
interface IFactory {
    
    /**
    * @notice Emitted when a controller creates a pool
    * @param caller The pool's creator
    * @param pool The created pool's address
    */
    event LOG_NEW_POOL(
        address indexed caller,
        address indexed pool
    );

    /**
    * @notice Emitted when a Swaap labs transfer is requested
    * @param from The current Swaap labs address
    * @param to The pending new Swaap labs address
    */
    event LOG_TRANSFER_REQUESTED(
        address indexed from,
        address indexed to
    );

    /**
    * @notice Emitted when a new address accepts the Swaap labs role
    * @param from The old Swaap labs address
    * @param to The new Swaap labs address
    */
    event LOG_NEW_SWAAPLABS(
        address indexed from,
        address indexed to
    );

    /*
    * @notice Create new pool with default parameters
    */
    function newPool() external returns (address);
    
    /**
    * @notice Returns if an address corresponds to a pool created by the factory
    */
    function isPool(address b) external view returns (bool);
    
    /**
    * @notice Returns swaap labs' address
    */
    function getSwaapLabs() external view returns (address);

    /**
    * @notice Allows an owner to begin transferring ownership to a new address,
    * pending.
    */
    function transferOwnership(address _to) external;

    /**
    * @notice Allows an ownership transfer to be completed by the recipient.
    */
    function acceptOwnership() external;
   
    /**
    * @notice Sends the exit fees accumulated to swaap labs
    */
    function collect(address erc20) external;

    /**
    * @notice Pause the factory's pools
    * @dev Pause disables most of the pools functionalities (swap, joinPool & joinswap)
    * and only allows LPs to withdraw their funds
    */
    function pauseProtocol() external;
    
    /**
    * @notice Resume the factory's pools
    * @dev Unpausing re-enables all the pools functionalities
    */
    function resumeProtocol() external;
    
    /**
    * @notice Reverts pools if the factory is paused
    * @dev This function is called by the pools whenever a swap or a joinPool is being made
    */
    function whenNotPaused() external view;

    /**
    * @notice Revoke factory control over a pool's parameters
    */
    function revokePoolFactoryControl(address pool) external;
    
    /**
    * @notice Sets a pool's swap fee
    */
    function setPoolSwapFee(address pool, uint256 swapFee) external;
    
    /**
    * @notice Sets a pool's dynamic coverage fees Z
    */
    function setPoolDynamicCoverageFeesZ(address pool, uint64 dynamicCoverageFeesZ) external;

    /**
    * @notice Sets a pool's dynamic coverage fees horizon
    */
    function setPoolDynamicCoverageFeesHorizon(address pool, uint256 dynamicCoverageFeesHorizon) external;

    /**
    * @notice Sets a pool's price statistics lookback in round
    */    
    function setPoolPriceStatisticsLookbackInRound(address pool, uint8 priceStatisticsLookbackInRound) external;

    /**
    * @notice Sets a pool's price statistics lookback in seconds
    */    
    function setPoolPriceStatisticsLookbackInSec(address pool, uint64 priceStatisticsLookbackInSec) external;

    /**
    * @notice Sets a pool's statistics lookback step in round
    */
    function setPoolPriceStatisticsLookbackStepInRound(address pool, uint8 priceStatisticsLookbackStepInRound) external;

    /**
    * @notice Sets a pool's maximum price unpeg ratio
    */
    function setPoolMaxPriceUnpegRatio(address pool, uint256 maxPriceUnpegRatio) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
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

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

import "./IPoolHelpers/IPoolLP.sol";
import "./IPoolHelpers/IPoolSwap.sol";
import "./IPoolHelpers/IPoolState.sol";
import "./IPoolHelpers/IPoolToken.sol";
import "./IPoolHelpers/IPoolEvents.sol";
import "./IPoolHelpers/IPoolControl.sol";

/**
* @title The interface for a Swaap V1 Pool
*/
interface IPool is 
    IPoolLP,
    IPoolSwap,
    IPoolState,
    IPoolToken,
    IPoolEvents,
    IPoolControl
{

}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

contract Struct {

    struct TokenGlobal {
        TokenRecord info;
        LatestRound latestRound;
    }

    struct LatestRound {
        address oracle;
        uint80  roundId;
        uint256 price;
        uint256 timestamp;
    }

    struct OracleState {
        address oracle;
        uint256 price;
    }

    struct HistoricalPricesParameters {
        uint8   lookbackInRound;
        uint256 lookbackInSec;
        uint256 timestamp;
        uint8   lookbackStepInRound;
    }
    
    struct HistoricalPricesData {
        uint256   startIndex;
        uint256[] timestamps;
        uint256[] prices;
    }
    
    struct SwapResult {
        uint256 amount;
        uint256 spread;
        uint256 taxBaseIn;
    }

    struct PriceResult {
        uint256 spotPriceBefore;
        uint256 spotPriceAfter;
        uint256 priceIn;
        uint256 priceOut;
    }

    struct GBMEstimation {
        int256  mean;
        uint256 variance;
        bool    success;
    }

    struct TokenRecord {
        uint8 decimals; // token decimals + oracle decimals
        uint256 balance;
        uint256 weight;
    }

    struct SwapParameters {
        uint256 amount;
        uint256 fee;
        uint256 fallbackSpread;
    }

    struct JoinExitSwapParameters {
        uint256 amount;
        uint256 fee;
        uint256 fallbackSpread;
        uint256 poolSupply;
    }

    struct GBMParameters {
        uint256 z;
        uint256 horizon;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

/**
* @title Contains the useful methods to a liquidity provider
*/
interface IPoolLP {
    
    /**
    * @notice Add liquidity to a pool and credit msg.sender
    * @dev The order of maxAmount of each token must be the same as the _tokens' addresses stored in the pool
    * @param poolAmountOut Amount of pool shares a LP wishes to receive
    * @param maxAmountsIn Maximum accepted token amount in
    */
    function joinPool(
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    )
    external;

    /**
    * @notice Get the token amounts in required and pool shares received when joining
    * the pool given an amount of tokenIn
    * @dev The amountIn of the specified token as input may differ at the exit due to
    * rounding discrepancies
    * @param  tokenIn The address of tokenIn
    * @param  tokenAmountIn The approximate amount of tokenIn to be swapped
    * @return poolAmountOut The pool amount out received
    * @return tokenAmountsIn The exact amounts of tokenIn needed
    */
    function getJoinPool(
        address tokenIn,
        uint256 tokenAmountIn
    )
    external
    view
    returns (uint256 poolAmountOut, uint256[] memory tokenAmountsIn);

    /**
    * @notice Remove liquidity from a pool
    * @dev The order of minAmount of each token must be the same as the _tokens' addresses stored in the pool
    * @param poolAmountIn Amount of pool shares a LP wishes to liquidate for tokens
    * @param minAmountsOut Minimum accepted token amount out
    */
    function exitPool(
        uint256 poolAmountIn,
        uint256[] calldata minAmountsOut
    )
    external;
    
    /**
    * @notice Get the token amounts received for a given pool shares in
    * @param poolAmountIn The amount of pool shares a LP wishes to liquidate for tokens
    * @return tokenAmountsOut The token amounts received
    */
    function getExitPool(uint256 poolAmountIn)
    external
    view
    returns (uint256[] memory tokenAmountsOut);

    /**
    * @notice Join a pool with a single asset with a fixed amount in
    * @dev The remaining tokens designate the tokens whose balances do not change during the joinswap
    * @param tokenIn The address of tokenIn
    * @param tokenAmountIn The amount of tokenIn to be added to the pool
    * @param minPoolAmountOut The minimum amount of pool tokens that can be received
    * @return poolAmountOut The received pool amount out
    */
    function joinswapExternAmountInMMM(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    )
    external
    returns (uint poolAmountOut);

    /**
    * @notice Computes the amount of pool tokens received when joining a pool with a single asset of fixed amount in
    * @dev The remaining tokens designate the tokens whose balances do not change during the joinswap
    * @param tokenIn The address of tokenIn
    * @param tokenAmountIn The amount of tokenIn to be added to the pool
    * @return poolAmountOut The received pool token amount out
    */
    function getJoinswapExternAmountInMMM(
        address tokenIn,
        uint256 tokenAmountIn
    )
    external
    view
    returns (uint256 poolAmountOut);

    /**
    * @notice Exit a pool with a single asset given the pool token amount in
    * @dev The remaining tokens designate the tokens whose balances do not change during the exitswap
    * @param tokenOut The address of tokenOut
    * @param poolAmountIn The fixed amount of pool tokens in
    * @param minAmountOut The minimum amount of token out that can be receied
    * @return tokenAmountOut The received token amount out
    */
    function exitswapPoolAmountInMMM(
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    )
    external
    returns (uint tokenAmountOut);

}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

import "../../structs/Struct.sol";

/**
* @title Contains the useful methods to a trader
*/
interface IPoolSwap{

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
    )
    external
    returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    /**
    * @notice Computes the amount of tokenOut received when swapping a fixed amount of tokenIn
    * @param tokenIn The address of the input token
    * @param tokenAmountIn The fixed amount of tokenIn to be swapped
    * @param tokenOut The address of the received token
    * @param minAmountOut The minimum amount of tokenOut that can be received
    * @param maxPrice The maximum spot price accepted before the swap
    * @return swapResult The swap result (amount out, spread and tax base in)
    * @return priceResult The price result (spot price before & after the swap, latest oracle price in & out)
    */
    function getAmountOutGivenInMMM(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    )
    external view
    returns (Struct.SwapResult memory swapResult, Struct.PriceResult memory priceResult);

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
    )
    external
    returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    /**
    * @notice Computes the amount of tokenIn needed to receive a fixed amount of tokenOut
    * @param tokenIn The address of the input token
    * @param maxAmountIn The maximum amount of tokenIn that can be swapped
    * @param tokenOut The address of the received token
    * @param tokenAmountOut The fixed accepted amount of tokenOut to be received
    * @param maxPrice The maximum spot price accepted before the swap
    * @return swapResult The swap result (amount in, spread and tax base in)
    * @return priceResult The price result (spot price before & after the swap, latest oracle price in & out)
    */
    function getAmountInGivenOutMMM(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    )
    external view
    returns (Struct.SwapResult memory swapResult, Struct.PriceResult memory priceResult);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

/**
* @title Contains the useful methods to get the Pool's parameters and state
*/
interface IPoolState{
    
    /**
    * @dev Returns true if a trader can swap on the pool
    */
    function isPublicSwap() external view returns (bool);

    /**
    * @dev Returns true if a liquidity provider can join the pool
    * A trader can swap on the pool if the pool is either finalized or isPublicSwap
    */
    function isFinalized() external view returns (bool);

    /**
    * @dev Returns true if the token is binded to the pool
    */
    function isBound(address t) external view returns (bool);

    /**
    * @dev Returns the binded tokens
    */
    function getTokens() external view returns (address[] memory tokens);
    
    /**
    * @dev Returns the initial weight of a binded token
    * The initial weight is the un-adjusted weight set by the controller at bind
    * The adjusted weight is the corrected weight based on the token's price performance:
    * adjusted_weight = initial_weight * current_price / initial_price
    */
    function getDenormalizedWeight(address token) external view returns (uint256);
    
    /**
    * @dev Returns the balance of a binded token
    */
    function getBalance(address token) external view returns (uint256);
    
    /**
    * @dev Returns the swap fee of the pool
    */
    function getSwapFee() external view returns (uint256);
    
    /**
    * @dev Returns the current controller of the pool
    */
    function getController() external view returns (address);
    
    /**
    * @dev Returns the coverage parameters of the pool
    */
    function getCoverageParameters() external view returns (
        uint8   priceStatisticsLBInRound,
        uint8   priceStatisticsLBStepInRound,
        uint64  dynamicCoverageFeesZ,
        uint256 dynamicCoverageFeesHorizon,
        uint256 priceStatisticsLBInSec,
        uint256 maxPriceUnpegRatio
    );

    /**
    * @dev Returns the token's price when it was binded to the pool
    */
    function getTokenOracleInitialPrice(address token) external view returns (uint256);

    /**
    * @dev Returns the oracle's address of a token
    */
    function getTokenPriceOracle(address token) external view returns (address);

    /**
    * @dev Absorb any tokens that have been sent to this contract into the pool
    * @param token The token's address
    */
    function gulp(address token) external;

    /**
    * @notice Returns the spot price without fees of a token pair
    * @return spotPrice The spot price of tokenOut in terms of tokenIn
    */
    function getSpotPriceSansFee(address tokenIn, address tokenOut) 
    external view
    returns (uint256 spotPrice);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
* @title Contains the external methods implemented by PoolToken
*/
interface IPoolToken is IERC20 {
    
    /**
    * @notice Returns token's name
    */
    function name() external pure returns (string memory name);

    /**
    * @notice Returns token's symbol
    */
    function symbol() external pure returns (string memory symbol);
    
    /**
    * @notice Returns token's decimals
    */
    function decimals() external pure returns(uint8 decimals);

    /**
    * @notice Increases an address approval by the input amount
    */
    function increaseApproval(address dst, uint256 amt) external returns (bool);

    /**
    * @notice Decreases an address approval by the input amount
    */
    function decreaseApproval(address dst, uint256 amt) external returns (bool);

}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

/**
* @title Contains the useful methods to a pool controller
*/
interface IPoolControl {

    /**
    * @notice Revokes factory control over pool parameters
    * @dev Factory control can only be revoked by the factory and not the pool controller
    */
    function revokeFactoryControl() external;

    /**
    * @notice Gives back factory control over the pool parameters
    */
    function giveFactoryControl() external;
    
    /**
    * @notice Allows a controller to transfer ownership to a new address
    * @dev It is recommended to use transferOwnership/acceptOwnership logic for safer transfers
    * to avoid any faulty input
    * This function is useful when creating pools using a proxy contract and transfer pool assets
    * WARNING: Binded assets are also transferred to the new controller if the pool is not finalized
    */  
    function setControllerAndTransfer(address controller) external;
    
    /**
    * @notice Allows a controller to begin transferring ownership to a new address
    * @dev The function will revert if there are binded tokens in an un-finalized pool
    * This prevents any accidental loss of funds for the current controller
    */
    function transferOwnership(address pendingController) external;
    
    /**
    * @notice Allows a controller transfer to be completed by the recipient
    */
    function acceptOwnership() external;
    
    /**
    * @notice Bind a new token to the pool
    * @param token The token's address
    * @param balance The token's balance
    * @param denorm The token's weight
    * @param priceFeedAddress The token's Chainlink price feed
    */
    function bindMMM(address token, uint256 balance, uint80 denorm, address priceFeedAddress) external;
    
    /**
    * @notice Replace a binded token's balance, weight and price feed's address
    * @param token The token's address
    * @param balance The token's balance
    * @param denorm The token's weight
    * @param priceFeedAddress The token's Chainlink price feed
    */
    function rebindMMM(address token, uint256 balance, uint80 denorm, address priceFeedAddress) external;
    
    /**
    * @notice Unbind a token from the pool
    * @dev The function will return the token's balance back to the controller
    * @param token The token's address
    */
    function unbindMMM(address token) external;
    
    /**
    * @notice Enables public swaps on the pool but does not finalize the parameters
    * @dev Unfinalized pool enables exclusively the controller to add liquidity into the pool
    */
    function setPublicSwap(bool publicSwap) external;

    /**
    * @notice Enables publicswap and finalizes the pool's tokens, price feeds, initial shares, balances and weights
    */
    function finalize() external;
    
    /** 
    * @notice Sets swap fee
    */
    function setSwapFee(uint256 swapFee) external;
    
    /**
    * @notice Sets dynamic coverage fees Z
    */
    function setDynamicCoverageFeesZ(uint64 dynamicCoverageFeesZ) external;
    
    /**
    * @notice Sets dynamic coverage fees horizon
    */
    function setDynamicCoverageFeesHorizon(uint256 dynamicCoverageFeesHorizon) external;
    
    /**
    * @notice Sets price statistics maximum lookback in round
    */
    function setPriceStatisticsLookbackInRound(uint8 priceStatisticsLookbackInRound) external;
    
    /** 
    * @notice Sets price statistics maximum lookback in seconds
    */
    function setPriceStatisticsLookbackStepInRound(uint8 priceStatisticsLookbackStepInRound) external;
    
    /**
    * @notice Sets price statistics lookback step in round
    * @dev This corresponds to the roundId lookback step when looking for historical prices
    */
    function setPriceStatisticsLookbackInSec(uint256 priceStatisticsLookbackInSec) external;

    /**
    * @notice Sets price statistics maximum unpeg ratio
    */
    function setMaxPriceUnpegRatio(uint256 maxPriceUnpegRatio) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.

// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.12;

/**
* @title Contains the pool's events
*/
interface IPoolEvents {
    
    /**
    * @notice Emitted after each swap
    * @param caller The trader's address
    * @param tokenIn The tokenIn's address
    * @param tokenOut The tokenOut's address
    * @param tokenAmountIn The amount of the swapped tokenIn
    * @param tokenAmountOut The amount of the swapped tokenOut
    * @param spread The spread
    * @param taxBaseIn The amount of tokenIn swapped when in shortage of tokenOut
    * @param priceIn The latest price of tokenIn given by the oracle
    * @param priceOut The latest price of tokenOut given by the oracle
    */
    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256         tokenAmountIn,
        uint256         tokenAmountOut,
        uint256         spread,
        uint256         taxBaseIn,
        uint256         priceIn,
        uint256         priceOut
    );

    /**
    * @notice Emitted when an LP joins the pool with 1 or multiple assets
    * @param caller The LP's address
    * @param tokenIn The dposited token's address
    * @param tokenAmountIn The deposited amount of tokenIn
    */
    event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint256         tokenAmountIn
    );

    /**
    * @notice Emitted when an LP withdraws one or multiple assets from the pool
    * @param caller The LP's address
    * @param tokenOut The withdrawn token's address
    * @param tokenAmountOut The withdrawn amount of tokenOut
    */
    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256         tokenAmountOut
    );

    /**
    * @param sig The function's signature
    * @param caller The caller's address
    * @param data The input data of the call
    */
    event LOG_CALL(
        bytes4  indexed sig,
        address indexed caller,
        bytes           data
    ) anonymous;

    /**
    * @notice Emitted when a new controller is assigned to the pool
    * @param from The previous controller's address
    * @param to The new controller's address
    */
    event LOG_NEW_CONTROLLER(
        address indexed from,
        address indexed to
    );

    /**
    * @notice Emitted when a token is binded/rebinded
    * @param token The binded token's address
    * @param oracle The assigned oracle's address
    * @param price The latest token's price reported by the oracle
    * @param description The oracle's description
    */
    event LOG_NEW_ORACLE_STATE(
        address indexed token,
        address oracle,
        uint256 price,
        uint8   decimals,
        string  description
    );

}