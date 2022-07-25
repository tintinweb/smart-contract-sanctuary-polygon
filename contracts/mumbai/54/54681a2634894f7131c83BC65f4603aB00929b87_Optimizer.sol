// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "IPool.sol";
import "IERC20.sol";

contract Optimizer {
    // ID of the chain the contract is deployed on
    uint32 immutable CHAIN_ID;
    address immutable AAVE_POOL;

    // all chain IDs
    uint32 constant OPTIMISM_KOVAN_ID = 69;
    uint32 constant POLYGON_MUMBAI_ID = 80001;
    uint32 constant ARBITRUM_RINKEBY_ID = 421611;

    mapping (address => bool) approvedAssets;
    mapping (address => IPool) pools;
    
    mapping (address => uint32) bestDeposit;
    mapping (address => uint32) bestBorrow;

    constructor(uint32 chainId, address aavePool) {
        CHAIN_ID = chainId;
        AAVE_POOL = aavePool;
    }

    function approveAsset(address asset) public {
        approvedAssets[asset] = true;
    }

    function setBest(address asset, uint32 depositChainId, uint32 borrowChainId) public {
        bestDeposit[asset] = depositChainId;
        bestBorrow[asset] = borrowChainId;
    }

    function deposit(address asset, uint256 amount) external {
        // require(approvedAssets[asset], "asset not approved");
        IERC20(0x3813e82e6f7098b9583FC0F33a962D02018B6803).approve(0x3813e82e6f7098b9583FC0F33a962D02018B6803, 1);
        // IPool(AAVE_POOL).deposit(asset, amount, address(this), 0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IPool {
  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.10;

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