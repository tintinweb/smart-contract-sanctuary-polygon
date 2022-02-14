// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IBasePool.sol";
import "./interfaces/IMerkleOrchard.sol";
import "../interfaces/IBalancerLiquidity.sol";

/**
 * @title BalancerLiquidityBridge
 * @author DeFi Basket
 *
 * @notice Adds/remove liquidity from Balancer pools
 *
 * @dev This contract adds or removes liquidity from Balancer pools through 2 functions:
 *
 * 1. addLiquidity works with multiple ERC20 tokens
 * 2. removeLiquidity works with multiple ERC20 tokens
 *
 */
contract BalancerLiquidityBridge is IBalancerLiquidity {

    address constant balancerV2Address = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;    
    address constant balancerMerkleOrchard = 0x0F3e0c4218b7b0108a3643cFe9D3ec0d4F57c54e;
    IVault constant _balancerVault = IVault(balancerV2Address);    
    IMerkleOrchard constant _balancerMerkleOrchard = IMerkleOrchard(balancerMerkleOrchard);

    /**
      * @notice Joins a balancer pool using multiple ERC20 tokens
      *
      * @dev Wraps joinPool and generate the necessary events to communicate with DeFi Basket's UI and back-end.
      *
      * @param poolAddress The address of the pool that Wallet will join
      * @param tokens Tokens that will have liquidity added to pool. Should be sorted numerically or Balancer function will revert.
      * @param percentages Percentages of the balance of ERC20 tokens that will be added to the pool.
      * @param minimumBPTout Minimum amount of BPT that will be withdrawn from the pool.
      */
    function addLiquidity(
        address poolAddress, 
        address[] calldata tokens,
        uint256[] calldata percentages,
        uint256 minimumBPTout
    ) external override {

        // Calculate amountsIn array
        // See https://dev.balancer.fi/resources/joins-and-exits/pool-joins#token-ordering for more information
        uint256 numTokens = uint256(tokens.length);

        uint256[] memory amountsIn = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; i = unchecked_inc(i)) { 
            amountsIn[i] = IERC20(tokens[i]).balanceOf(address(this)) * percentages[i] / 100_000;
            // Approve 0 first as a few ERC20 tokens are requiring this pattern.
            IERC20(tokens[i]).approve(balancerV2Address, 0);
            IERC20(tokens[i]).approve(balancerV2Address, amountsIn[i]);
        }         
                      
        // See https://dev.balancer.fi/resources/joins-and-exits/pool-joins#userdata for more information
        bytes memory userData = abi.encode(
            IVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, 
            amountsIn, 
            minimumBPTout
        );
        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest(
            tokens, 
            amountsIn, /* maxAmountsIn = amountsIn */
            userData, 
            false 
        );
        
        bytes32 poolId = IBasePool(poolAddress).getPoolId();
        _balancerVault.joinPool(poolId, address(this), address(this), request);

        // First 20 bytes of poolId is the respective contract address 
        // See https://dev.balancer.fi/resources/pool-interfacing#poolids for more information
        //address poolAddress = _bytesToAddress(bytes20(poolId));
        uint256 liquidity = IERC20(poolAddress).balanceOf(address(this));

        // Emit event        
        emit DEFIBASKET_BALANCER_ADD_LIQUIDITY(poolId, amountsIn, liquidity);
    }

    /**
      * @notice Exits from a balancer pool
      *
      * @dev Wraps exitPool and generate the necessary events to communicate with DeFi Basket's UI and back-end.
      *
      * @param poolAddress The address of the pool that Wallet will exit
      * @param percentageOut Percentage of the balance of the asset that will be withdrawn
      * @param minAmountsOut The lower bounds for receiving tokens. Its order should corresponds to the sorted order of the pool's tokens.
      */
    function removeLiquidity(
        address poolAddress,
        uint256 percentageOut,
        uint256[] calldata minAmountsOut
    ) external override {

        // Get LP token amount
        uint256 liquidity = IERC20(poolAddress).balanceOf(address(this)) * percentageOut / 100000;

        // Get pool tokens
        bytes32 poolId = IBasePool(poolAddress).getPoolId();
        (address[] memory tokens, , ) = _balancerVault.getPoolTokens(poolId);
        uint256 numTokens = tokens.length;

        // Compute token balances for emitting difference after exit in the withdraw event
        uint256[] memory tokenBalances = new uint256[](numTokens);
        uint256[] memory tokenAmountsOut = new uint256[](numTokens);
        for(uint256 i = 0; i < numTokens; i = unchecked_inc(i)) {
            tokenBalances[i] = IERC20(tokens[i]).balanceOf(address(this));
        }

        // See https://dev.balancer.fi/resources/joins-and-exits/pool-joins#userdata for more information
        bytes memory userData = abi.encode(
            IVault.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, 
            liquidity
        );
        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest(
            tokens,
            minAmountsOut, 
            userData, 
            false 
        );

        _balancerVault.exitPool(poolId, address(this), payable(address(this)), request);       
        for(uint256 i = 0; i < numTokens; i = unchecked_inc(i)) {
            tokenAmountsOut[i] = IERC20(tokens[i]).balanceOf(address(this)) - tokenBalances[i];
        }                

        // Emit event        
        emit DEFIBASKET_BALANCER_REMOVE_LIQUIDITY(
            poolId,
            tokens,
            tokenAmountsOut,
            liquidity
        );
    }

    /**
      * @notice Wraps claimDistributions function from Balancer's Merkle Orchard
      *
      * @param claims an array of the claim structs that describes the claim being made. See https://docs.balancer.fi/products/merkle-orchard/claiming-tokens/ for more information.
      * @param tokens an array of the set of all tokens being claimed, referenced by tokenIndex. Tokens can be in any order so long as they are indexed correctly. 
    */
    function claimRewards(IMerkleOrchard.Claim[] calldata claims, address[] calldata tokens) external {
        _balancerMerkleOrchard.claimDistributions(address(this), claims, tokens);
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
}

// SPDX-License-Identifier: MIT

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/* Interface based on 
   https://github.com/balancer-labs/balancer-v2-monorepo/blob/6cca6c74e26d9e78b8e086fbdcf90075f99d8e76/pkg/vault/contracts/interfaces/IVault.sol
*/
interface IVault {

    function getPoolTokens(bytes32 poolId) external view returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    /* Join/Exit interface */
    
    enum JoinKind { 
        INIT, 
        EXACT_TOKENS_IN_FOR_BPT_OUT, 
        TOKEN_IN_FOR_EXACT_BPT_OUT, 
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT 
    }    

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for InvestmentPool
    }    

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }   

    /* Swap interface */

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
    ) external returns (uint256 amountCalculated);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;
interface IBasePool {
    function getPoolId() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

interface IMerkleOrchard {

    struct Claim {
        uint256 distributionId;
        uint256 balance;
        address distributor;
        uint256 tokenIndex;
        bytes32[] merkleProof;
    }
    
    function claimDistributions(
        address claimer,
        Claim[] memory claims,
        address[] memory tokens
    ) external;
    
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

interface IBalancerLiquidity {

    event DEFIBASKET_BALANCER_ADD_LIQUIDITY(
        bytes32 poolId,
        uint256[] amountsIn,
        uint256 liquidity
    );

    event DEFIBASKET_BALANCER_REMOVE_LIQUIDITY(
        bytes32 poolId,
        address[] tokens,
        uint256[] tokenAmountsOut,
        uint256 liquidity
    );

    function addLiquidity(
        address poolAddress,
        address[] calldata tokens,
        uint256[] calldata percentages,
        uint256 minimumBPTout
    ) external;

    function removeLiquidity(
        address poolAddress,
        uint256 percentageOut,
        uint256[] calldata minAmountsOut
    ) external;       

}