// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICurveBasePool.sol";
import "./interfaces/ICurveRewardGauge.sol";
import "./interfaces/ICurveAddressRegistry.sol";
import "./interfaces/ICurvePoolsRegistry.sol";
import "../interfaces/ICurveLiquidity.sol";

/**
 * @title CurveLiquidityBridge
 * @author DeFi Basket
 *
 * @notice Adds/remove liquidity from Curve pools
 *
 * @dev This contract adds or removes liquidity from Curve pools
 *
 */
contract CurveLiquidityBridge is ICurveLiquidity {

    address constant curveAddressRegistry = 0x0000000022D53366457F9d5E68Ec105046FC4383;
    ICurveAddressRegistry constant _addressRegistry = ICurveAddressRegistry(curveAddressRegistry);

    /**
      * @notice Joins a Curve pool using multiple ERC20 tokens and stake the received LP token
      *
      * @dev Wraps add_liquidity and generate the necessary events to communicate with DeFi Basket's UI and back-end.
      *      Note: This function does not automatically stake the LP token.
      *      Note: This function could be optimized if we remove `tokens` argument
      *
      * @param poolAddress The address of the pool that Wallet will join
      * @param tokens Tokens that will be added to pool. Should be sorted according to the Curve's pool order, otherwise function will revert
      * @param percentages Percentages of the balance of ERC20 tokens that will be added to the pool.
      * @param minAmountOut Minimum amount of LP token that should be received from the pool
      */
    function addLiquidity(
        address poolAddress,
        address[] calldata tokens, /* Must be in the same order as the array returned by underlying_coins (or coins) */
        uint256[] calldata percentages,
        uint256 minAmountOut
    ) external override {
        uint256 numTokens = uint256(tokens.length);
        uint256[] memory amountsIn = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i = unchecked_inc(i)) {
            amountsIn[i] = IERC20(tokens[i]).balanceOf(address(this)) * percentages[i] / 100_000;
            // Approve 0 first as a few ERC20 tokens are requiring this pattern.
            IERC20(tokens[i]).approve(poolAddress, 0);
            IERC20(tokens[i]).approve(poolAddress, amountsIn[i]);
        }

        // Call the correct add_liquidity function according to tokens array size
        uint256 liquidity;
        if(numTokens == 2){
            uint256[2] memory amts = [amountsIn[0], amountsIn[1]];
            try ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut, true) returns (uint256 LPTokenReceived) {
                liquidity = LPTokenReceived;
            } catch {
                liquidity = ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut);
            }
        }else if(numTokens == 3){
            uint256[3] memory amts = [amountsIn[0], amountsIn[1], amountsIn[2]];
            try ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut, true) returns (uint256 LPTokenReceived) {
                liquidity = LPTokenReceived;
            } catch {
                liquidity = ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut);
            }

        }else if(numTokens == 4){
            uint256[4] memory amts = [amountsIn[0], amountsIn[1], amountsIn[2], amountsIn[3]];
            try ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut, true) returns (uint256 LPTokenReceived) {
                liquidity = LPTokenReceived;
            } catch {
                liquidity = ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut);
            }
        }else if(numTokens == 5){
            uint256[5] memory amts = [amountsIn[0], amountsIn[1], amountsIn[2], amountsIn[3], amountsIn[4]];
            try ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut, true) returns (uint256 LPTokenReceived) {
                liquidity = LPTokenReceived;
            } catch {
                liquidity = ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut);
            }
        }else if(numTokens == 6){
            uint256[6] memory amts = [amountsIn[0], amountsIn[1], amountsIn[2], amountsIn[3], amountsIn[4], amountsIn[5]];
            try ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut, true) returns (uint256 LPTokenReceived) {
                liquidity = LPTokenReceived;
            } catch {
                liquidity = ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut);
            }
        }else if(numTokens == 7){
            uint256[7] memory amts = [amountsIn[0], amountsIn[1], amountsIn[2], amountsIn[3], amountsIn[4], amountsIn[5], amountsIn[6]];
            try ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut, true) returns (uint256 LPTokenReceived) {
                liquidity = LPTokenReceived;
            } catch {
                liquidity = ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut);
            }
        }else if(numTokens == 8){
            uint256[8] memory amts = [amountsIn[0], amountsIn[1], amountsIn[2], amountsIn[3], amountsIn[4], amountsIn[5], amountsIn[6], amountsIn[7]];
            try ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut, true) returns (uint256 LPTokenReceived) {
                liquidity = LPTokenReceived;
            } catch {
                liquidity = ICurveBasePool(poolAddress).add_liquidity(amts, minAmountOut);
            }
        }else{
            revert("Unsupported number of tokens");
        }

        // Emit event
        emit DEFIBASKET_CURVE_ADD_LIQUIDITY(amountsIn, liquidity);
    }

    /**
      * @notice Unstake LP token from a Curve pool and withdraw assets
      *
      * @dev Wraps withdraw/remove_liquidity and generate the necessary events to communicate with DeFi Basket's UI and back-end.
      *
      * @param poolAddress The address of the pool that Wallet will withdraw assets
      * @param percentageOut Percentages of LP token that will be withdrawn from the pool.
      * @param minAmountsOut Minimum amount of tokens that should be received from the pool. Should be in the same order than underlying_coins from the pool
      */
    function removeLiquidity(
        address poolAddress,
        address LPtokenAddress,
        uint256 percentageOut,
        uint256[] calldata minAmountsOut
    ) external override {
        uint256 numTokens = minAmountsOut.length;
        uint256 liquidity;

        liquidity = IERC20(LPtokenAddress).balanceOf(address(this)) * percentageOut / 100_000;

        uint256[] memory amountsOut = new uint256[](numTokens);

        // Call the correct remove_liquidity interface according to tokens array size
        if(numTokens == 2){
            uint256[2] memory min_amts = [minAmountsOut[0], minAmountsOut[1]];
            uint256[2] memory tokensAmountsOut = ICurveBasePool(poolAddress).remove_liquidity(liquidity, min_amts);
            amountsOut[0] = tokensAmountsOut[0];
            amountsOut[1] = tokensAmountsOut[1];
        }else if(numTokens == 3){
            uint256[3] memory min_amts = [minAmountsOut[0], minAmountsOut[1], minAmountsOut[2]];
            uint256[3] memory tokensAmountsOut = ICurveBasePool(poolAddress).remove_liquidity(liquidity, min_amts);
            amountsOut[0] = tokensAmountsOut[0];
            amountsOut[1] = tokensAmountsOut[1];
            amountsOut[2] = tokensAmountsOut[2];
        }else if(numTokens == 4){
            uint256[4] memory min_amts = [minAmountsOut[0], minAmountsOut[1], minAmountsOut[2], minAmountsOut[3]];
            uint256[4] memory tokensAmountsOut = ICurveBasePool(poolAddress).remove_liquidity(liquidity, min_amts);
            amountsOut[0] = tokensAmountsOut[0];
            amountsOut[1] = tokensAmountsOut[1];
            amountsOut[2] = tokensAmountsOut[2];
            amountsOut[3] = tokensAmountsOut[3];
        }else if(numTokens == 5){
            uint256[5] memory min_amts = [minAmountsOut[0], minAmountsOut[1], minAmountsOut[2], minAmountsOut[3], minAmountsOut[4]];
            uint256[5] memory tokensAmountsOut = ICurveBasePool(poolAddress).remove_liquidity(liquidity, min_amts);
            amountsOut[0] = tokensAmountsOut[0];
            amountsOut[1] = tokensAmountsOut[1];
            amountsOut[2] = tokensAmountsOut[2];
            amountsOut[3] = tokensAmountsOut[3];
            amountsOut[4] = tokensAmountsOut[4];
        }else if(numTokens == 6){
            uint256[6] memory min_amts = [minAmountsOut[0], minAmountsOut[1], minAmountsOut[2], minAmountsOut[3], minAmountsOut[4], minAmountsOut[5]];
            uint256[6] memory tokensAmountsOut = ICurveBasePool(poolAddress).remove_liquidity(liquidity, min_amts);
            amountsOut[0] = tokensAmountsOut[0];
            amountsOut[1] = tokensAmountsOut[1];
            amountsOut[2] = tokensAmountsOut[2];
            amountsOut[3] = tokensAmountsOut[3];
            amountsOut[4] = tokensAmountsOut[4];
            amountsOut[5] = tokensAmountsOut[5];
        }else if(numTokens == 7){
            uint256[7] memory min_amts = [minAmountsOut[0], minAmountsOut[1], minAmountsOut[2], minAmountsOut[3], minAmountsOut[4], minAmountsOut[5], minAmountsOut[6]];
            uint256[7] memory tokensAmountsOut = ICurveBasePool(poolAddress).remove_liquidity(liquidity, min_amts);
            amountsOut[0] = tokensAmountsOut[0];
            amountsOut[1] = tokensAmountsOut[1];
            amountsOut[2] = tokensAmountsOut[2];
            amountsOut[3] = tokensAmountsOut[3];
            amountsOut[4] = tokensAmountsOut[4];
            amountsOut[5] = tokensAmountsOut[5];
            amountsOut[6] = tokensAmountsOut[6];
        }else if(numTokens == 8){
            uint256[8] memory min_amts = [minAmountsOut[0], minAmountsOut[1], minAmountsOut[2], minAmountsOut[3], minAmountsOut[4], minAmountsOut[5], minAmountsOut[6], minAmountsOut[7]];
            uint256[8] memory tokensAmountsOut = ICurveBasePool(poolAddress).remove_liquidity(liquidity, min_amts);
            amountsOut[0] = tokensAmountsOut[0];
            amountsOut[1] = tokensAmountsOut[1];
            amountsOut[2] = tokensAmountsOut[2];
            amountsOut[3] = tokensAmountsOut[3];
            amountsOut[4] = tokensAmountsOut[4];
            amountsOut[5] = tokensAmountsOut[5];
            amountsOut[6] = tokensAmountsOut[6];
            amountsOut[7] = tokensAmountsOut[7];
        }else{
            revert("Unsupported number of tokens");
        }

        // Emit event
        emit DEFIBASKET_CURVE_REMOVE_LIQUIDITY(
            amountsOut,
            liquidity
        );
    }

    /**
      * @notice Increment integer without checking for overflow - only use in loops where you know the value won't overflow
      *
      * @param i Integer to be incremented
    */
    function unchecked_inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    function removeLiquidityOneToken(
        address poolAddress,
        address LPTokenAddress,
        int128 tokenIndex,
        uint256 percentageOut,
        uint256 minAmountOut
    ) external override
    {
        uint256 liquidity = IERC20(LPTokenAddress).balanceOf(address(this)) * percentageOut / 100_000;
        uint256 amountOut = ICurveBasePool(poolAddress).remove_liquidity_one_coin(liquidity, tokenIndex, minAmountOut);
        emit DEFIBASKET_CURVE_REMOVE_LIQUIDITY_ONE_COIN(liquidity, amountOut);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address from,
        address to,
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

// Based on https://github.com/curvefi/curve-contract/blob/master/contracts/pool-templates/y/SwapTemplateY.vy
interface ICurveBasePool {

    // Curve add_liquidity functions use static arrays, so we have different function selectors for each one of them
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[5] calldata amounts, uint256 min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[6] calldata amounts, uint256 min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[7] calldata amounts, uint256 min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[8] calldata amounts, uint256 min_mint_amount) external returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount, bool use_underlying) external returns (uint256);
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount, bool use_underlying) external returns (uint256);
    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount, bool use_underlying) external returns (uint256);
    function add_liquidity(uint256[5] calldata amounts, uint256 min_mint_amount, bool use_underlying) external returns (uint256);
    function add_liquidity(uint256[6] calldata amounts, uint256 min_mint_amount, bool use_underlying) external returns (uint256);
    function add_liquidity(uint256[7] calldata amounts, uint256 min_mint_amount, bool use_underlying) external returns (uint256);
    function add_liquidity(uint256[8] calldata amounts, uint256 min_mint_amount, bool use_underlying) external returns (uint256);

    // Curve remove_liquidity functions use static arrays, so we have different function selectors for each one of them
    function remove_liquidity(uint256 _amount, uint256[2] calldata _min_amounts) external returns (uint256[2] memory);
    function remove_liquidity(uint256 _amount, uint256[3] calldata _min_amounts) external returns (uint256[3] memory);
    function remove_liquidity(uint256 _amount, uint256[4] calldata _min_amounts) external returns (uint256[4] memory);
    function remove_liquidity(uint256 _amount, uint256[5] calldata _min_amounts) external returns (uint256[5] memory);
    function remove_liquidity(uint256 _amount, uint256[6] calldata _min_amounts) external returns (uint256[6] memory);
    function remove_liquidity(uint256 _amount, uint256[7] calldata _min_amounts) external returns (uint256[7] memory);
    function remove_liquidity(uint256 _amount, uint256[8] calldata _min_amounts) external returns (uint256[8] memory);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

// Based on https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/gauges/LiquidityGaugeReward.vy
interface ICurveRewardGauge {

    function deposit(
        uint256 amount,     // amount to deposit in reward gauge
        address receiver  // address to deposit for
    ) external;

    function withdraw(
        uint256 amount,     // amount to withdraw from reward gauge
        bool claim_rewards  // whether to claim rewards
    ) external;

    function reward_tokens(
        uint256 index     // index of reward to claim (Max: 8)
    ) external returns(address);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

// Based on https://github.com/curvefi/curve-pool-registry/blob/master/contracts/AddressProvider.vy
interface ICurveAddressRegistry {

    function get_registry() external view returns (address);    

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

// Based on https://github.com/curvefi/curve-pool-registry/blob/master/contracts/Registry.vy
interface ICurvePoolsRegistry {

    function get_n_coins(uint256 i) external view returns (uint256); // 0: coins, 1: underlying coins
    function get_coins(address _pool) external view returns (address[8] memory);
    function get_underlying_coins(address _pool) external view returns (address[8] memory);
    function get_gauges(address pool) external view returns (address[10] memory);

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

interface ICurveLiquidity {
    event DEFIBASKET_CURVE_ADD_LIQUIDITY(
        uint256[] amountsIn,
        uint256 liquidity
    );

    event DEFIBASKET_CURVE_REMOVE_LIQUIDITY(
        uint256[] tokenAmountsOut,
        uint256 liquidity
    );

    event DEFIBASKET_CURVE_REMOVE_LIQUIDITY_ONE_COIN(
        uint256 amountIn,
        uint256 amountOut
    );

    function addLiquidity(
        address poolAddress,
        address[] memory tokens,
        uint256[] calldata percentages,
        uint256 minAmountOut
    ) external;

    function removeLiquidity(
        address poolAddress,
        address LPtokenAddress,
        uint256 percentageOut,
        uint256[] calldata minAmountsOut
    ) external;

    function removeLiquidityOneToken(
        address poolAddress,
        address LPTokenAddress,
        int128 tokenIndex,
        uint256 percentageOut,
        uint256 minAmountOut
    ) external;
}