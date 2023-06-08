// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

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
  function approve(address spender, uint amount) external returns (bool);

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
    uint amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.17;

import "./IERC20.sol";

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v4.6/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity 0.8.17;

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

pragma solidity 0.8.17;

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.17;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Permit.sol";
import "./Address.sol";

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

// SPDX-License-Identifier: ISC
pragma solidity 0.8.17;

interface IBalancerGauge {
  function decimals() external view returns (uint256);

  function version() external view returns (string memory);

  function last_claim() external view returns (uint256);

  function claimed_reward(address _addr, address _token) external view returns (uint256);

  function claimable_reward(address _addr, address _token) external view returns (uint256);

  function claimable_reward_write(address _addr, address _token) external returns (uint256);

  function reward_contract() external view returns (address);

  function reward_data(address _token) external view returns (
    address token,
    address distributor,
    uint256 period_finish,
    uint256 rate,
    uint256 last_update,
    uint256 integral
  );

  function reward_tokens(uint256 arg0) external view returns (address);

  function reward_balances(address arg0) external view returns (uint256);

  function rewards_receiver(address arg0) external view returns (address);

  function reward_integral(address arg0) external view returns (uint256);

  function reward_integral_for(address arg0, address arg1) external view returns (uint256);

  function set_rewards_receiver(address _receiver) external;

  function set_rewards(
    address _reward_contract,
    bytes32 _claim_sig,
    address[8] memory _reward_tokens
  ) external;

  function claim_rewards() external;

  function claim_rewards(address _addr) external;

  function claim_rewards(address _addr, address _receiver) external;

  function deposit(uint256 _value) external;

  function deposit(uint256 _value, address _addr) external;

  function deposit(uint256 _value, address _addr, bool _claim_rewards) external;

  function withdraw(uint256 _value) external;

  function withdraw(uint256 _value, bool _claim_rewards) external;

  function transfer(address _to, uint256 _value) external returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address _spender, uint256 _value) external returns (bool);

  function permit(
    address _owner,
    address _spender,
    uint256 _value,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external returns (bool);

  function increaseAllowance(address _spender, uint256 _added_value) external returns (bool);

  function decreaseAllowance(address _spender, uint256 _subtracted_value) external returns (bool);

  function initialize(
    address _lp_token,
    address _reward_contract,
    bytes32 _claim_sig
  ) external;

  function lp_token() external view returns (address);

  function balanceOf(address arg0) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function nonces(address arg0) external view returns (uint256);

  function claim_sig() external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IBVault.sol";

interface IBalancerHelper {
  function queryExit(
    bytes32 poolId,
    address sender,
    address recipient,
    IBVault.ExitPoolRequest memory request
  ) external returns (uint256 bptIn, uint256[] memory amountsOut);

  function queryJoin(
    bytes32 poolId,
    address sender,
    address recipient,
    IBVault.JoinPoolRequest memory request
  ) external returns (uint256 bptOut, uint256[] memory amountsIn);

  function vault() external view returns (address);
}

// SPDX-License-Identifier: ISC
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20.sol";

interface IAsset {
}

interface IBVault {
  // Internal Balance
  //
  // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
  // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
  // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
  // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
  //
  // Internal Balance management features batching, which means a single contract call can be used to perform multiple
  // operations of different kinds, with different senders and recipients, at once.

  /**
   * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
  function getInternalBalance(address user, IERC20[] calldata tokens) external view returns (uint256[] memory);

  /**
   * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
  function manageUserBalance(UserBalanceOp[] calldata ops) external payable;

  /**
   * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
  struct UserBalanceOp {
    UserBalanceOpKind kind;
    IAsset asset;
    uint256 amount;
    address sender;
    address payable recipient;
  }

  // There are four possible operations in `manageUserBalance`:
  //
  // - DEPOSIT_INTERNAL
  // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
  // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
  //
  // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
  // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
  // relevant for relayers).
  //
  // Emits an `InternalBalanceChanged` event.
  //
  //
  // - WITHDRAW_INTERNAL
  // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
  //
  // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
  // it to the recipient as ETH.
  //
  // Emits an `InternalBalanceChanged` event.
  //
  //
  // - TRANSFER_INTERNAL
  // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
  //
  // Reverts if the ETH sentinel value is passed.
  //
  // Emits an `InternalBalanceChanged` event.
  //
  //
  // - TRANSFER_EXTERNAL
  // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
  // relayers, as it lets them reuse a user's Vault allowance.
  //
  // Reverts if the ETH sentinel value is passed.
  //
  // Emits an `ExternalBalanceTransfer` event.

  enum UserBalanceOpKind {DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL}

  /**
   * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
  event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

  /**
   * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
  event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

  // Pools
  //
  // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
  // functionality:
  //
  //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
  // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
  // which increase with the number of registered tokens.
  //
  //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
  // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
  // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
  // independent of the number of registered tokens.
  //
  //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
  // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

  enum PoolSpecialization {GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN}

  /**
   * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
  function registerPool(PoolSpecialization specialization) external returns (bytes32);

  /**
   * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
  event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

  /**
   * @dev Returns a Pool's contract address and specialization setting.
     */
  function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

  /**
   * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
  function registerTokens(
    bytes32 poolId,
    IERC20[] calldata tokens,
    address[] calldata assetManagers
  ) external;

  /**
   * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
  event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

  /**
   * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
  function deregisterTokens(bytes32 poolId, IERC20[] calldata tokens) external;

  /**
   * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
  event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

  /**
   * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
  function getPoolTokenInfo(bytes32 poolId, IERC20 token)
  external
  view
  returns (
    uint256 cash,
    uint256 managed,
    uint256 lastChangeBlock,
    address assetManager
  );

  /**
   * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
  function getPoolTokens(bytes32 poolId)
  external
  view
  returns (
    IERC20[] memory tokens,
    uint256[] memory balances,
    uint256 lastChangeBlock
  );

  /**
   * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     *
     * See https://dev.balancer.fi/resources/joins-and-exits/pool-joins
     */
  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest calldata request
  ) external payable;

  enum JoinKind {INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT}

  /// @notice WeightedPool ExitKinds
  enum ExitKind {EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT}
  /// @notice Composable Stable V2 ExitKinds
  enum ExitKindComposableStable {EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT, EXACT_BPT_IN_FOR_ALL_TOKENS_OUT}


  struct JoinPoolRequest {
    IAsset[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  /**
   * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
  function exitPool(
    bytes32 poolId,
    address sender,
    address payable recipient,
    ExitPoolRequest calldata request
  ) external;

  struct ExitPoolRequest {
    IAsset[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
  }

  /**
   * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
  event PoolBalanceChanged(
    bytes32 indexed poolId,
    address indexed liquidityProvider,
    IERC20[] tokens,
    int256[] deltas,
    uint256[] protocolFeeAmounts
  );

  enum PoolBalanceChangeKind {JOIN, EXIT}

  // Swaps
  //
  // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
  // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
  // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
  //
  // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
  // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
  // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
  // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
  // individual swaps.
  //
  // There are two swap kinds:
  //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
  // `onSwap` hook) the amount of tokens out (to send to the recipient).
  //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
  // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
  //
  // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
  // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
  // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
  // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
  // the final intended token.
  //
  // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
  // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
  // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
  // much less gas than they would otherwise.
  //
  // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
  // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
  // updating the Pool's internal accounting).
  //
  // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
  // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
  // minimum amount of tokens to receive (by passing a negative value) is specified.
  //
  // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
  // this point in time (e.g. if the transaction failed to be included in a block promptly).
  //
  // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
  // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
  // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
  // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
  //
  // Finally, Internal Balance can be used when either sending or receiving tokens.

  enum SwapKind {GIVEN_IN, GIVEN_OUT}

  /**
   * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
  function swap(
    SingleSwap calldata singleSwap,
    FundManagement calldata funds,
    uint256 limit,
    uint256 deadline
  ) external payable returns (uint256);

  /**
   * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
  struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
  }

  /**
   * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
  function batchSwap(
    SwapKind kind,
    BatchSwapStep[] calldata swaps,
    IAsset[] calldata assets,
    FundManagement calldata funds,
    int256[] calldata limits,
    uint256 deadline
  ) external payable returns (int256[] memory);

  /**
   * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  /**
   * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
  event Swap(
    bytes32 indexed poolId,
    IERC20 indexed tokenIn,
    IERC20 indexed tokenOut,
    uint256 amountIn,
    uint256 amountOut
  );

  /**
   * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
  }

  /**
   * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
  function queryBatchSwap(
    SwapKind kind,
    BatchSwapStep[] calldata swaps,
    IAsset[] calldata assets,
    FundManagement calldata funds
  ) external returns (int256[] memory assetDeltas);

  // BasePool.sol

  /**
* @dev Returns the amount of BPT that would be burned from `sender` if the `onExitPool` hook were called by the
     * Vault with the same arguments, along with the number of tokens `recipient` would receive.
     *
     * This function is not meant to be called directly, but rather from a helper contract that fetches current Vault
     * data, such as the protocol swap fee percentage and Pool balances.
     *
     * Like `IVault.queryBatchSwap`, this function is not view due to internal implementation details: the caller must
     * explicitly use eth_call instead of eth_sendTransaction.
     */
  function queryExit(
    bytes32 poolId,
    address sender,
    address recipient,
    uint256[] memory balances,
    uint256 lastChangeBlock,
    uint256 protocolSwapFeePercentage,
    bytes memory userData
  ) external returns (uint256 bptIn, uint256[] memory amountsOut);


}

// SPDX-License-Identifier: ISC
pragma solidity 0.8.17;

interface IComposableStablePool {
  function balanceOf(address account) external view returns (uint256);
  function getActualSupply() external view returns (uint256);
  function getPoolId() external view returns (bytes32);
  function getBptIndex() external view returns (uint256);
  function updateTokenRateCache(address token) external;
}

// SPDX-License-Identifier: ISC
pragma solidity 0.8.17;

interface ILinearPool {
  function getPoolId() external view returns (bytes32);

  function getMainIndex() external view returns (uint);

  function getMainToken() external view returns (address);

  function getWrappedIndex() external view returns (uint);

  function getWrappedToken() external view returns (address);

  function getWrappedTokenRate() external view returns (uint);

  function getRate() external view returns (uint);

  function getBptIndex() external pure returns (uint);

  function getVirtualSupply() external view returns (uint);

  function getSwapFeePercentage() external view returns (uint);

  function getTargets() external view returns (uint lowerTarget, uint upperTarget);

  function totalSupply() external view returns (uint);

  function getScalingFactors() external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice List of all errors generated by the application
///         Each error should have unique code TS-XXX and descriptive comment
library AppErrors {
  /// @notice Provided address should be not zero
  string public constant ZERO_ADDRESS = "TS-1 zero address";

  /// @notice A pair of the tokens cannot be found in the factory of uniswap pairs
  string public constant UNISWAP_PAIR_NOT_FOUND = "TS-2 pair not found";

  /// @notice Lengths not matched
  string public constant WRONG_LENGTHS = "TS-4 wrong lengths";

  /// @notice Unexpected zero balance
  string public constant ZERO_BALANCE = "TS-5 zero balance";

  string public constant ITEM_NOT_FOUND = "TS-6 not found";

  string public constant NOT_ENOUGH_BALANCE = "TS-7 not enough balance";

  /// @notice Price oracle returns zero price
  string public constant ZERO_PRICE = "TS-8 zero price";

  string public constant WRONG_VALUE = "TS-9 wrong value";

  /// @notice TetuConvertor wasn't able to make borrow, i.e. borrow-strategy wasn't found
  string public constant ZERO_AMOUNT_BORROWED = "TS-10 zero borrowed amount";

  string public constant WITHDRAW_TOO_MUCH = "TS-11 try to withdraw too much";

  string public constant UNKNOWN_ENTRY_KIND = "TS-12 unknown entry kind";

  string public constant ONLY_TETU_CONVERTER = "TS-13 only TetuConverter";

  string public constant WRONG_ASSET = "TS-14 wrong asset";

  string public constant NO_LIQUIDATION_ROUTE = "TS-15 No liquidation route";

  string public constant PRICE_IMPACT = "TS-16 price impact";

  /// @notice tetuConverter_.repay makes swap internally. It's not efficient and not allowed
  string public constant REPAY_MAKES_SWAP = "TS-17 can not convert back";

  string public constant NO_INVESTMENTS = "TS-18 no investments";

  string public constant INCORRECT_LENGTHS = "TS-19 lengths";

  /// @notice We expect increasing of the balance, but it was decreased
  string public constant BALANCE_DECREASE = "TS-20 balance decrease";

  /// @notice Prices changed and invested assets amount was increased on S, value of S is too high
  string public constant EARNED_AMOUNT_TOO_HIGH = "TS-21 earned too high";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20Metadata.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/SafeERC20.sol";

/// @notice Common internal utils
library AppLib {
  using SafeERC20 for IERC20;

  /// @notice Unchecked increment for for-cycles
  function uncheckedInc(uint i) internal pure returns (uint) {
    unchecked {
      return i + 1;
    }
  }

  /// @notice Make infinite approve of {token} to {spender} if the approved amount is less than {amount}
  /// @dev Should NOT be used for third-party pools
  function approveIfNeeded(address token, uint amount, address spender) internal {
    if (IERC20(token).allowance(address(this), spender) < amount) {
      IERC20(token).safeApprove(spender, 0);
      // infinite approve, 2*255 is more gas efficient then type(uint).max
      IERC20(token).safeApprove(spender, 2 ** 255);
    }
  }

  function balance(address token) internal view returns (uint) {
    return IERC20(token).balanceOf(address(this));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./AppErrors.sol";

/// @title Library for clearing / joining token addresses & amounts arrays
/// @author bogdoslav
library TokenAmountsLib {
  /// @notice Version of the contract
  /// @dev Should be incremented when contract changed
  string internal constant TOKEN_AMOUNTS_LIB_VERSION = "1.0.1";

  function uncheckedInc(uint i) internal pure returns (uint) {
    unchecked {
      return i + 1;
    }
  }

  function filterZeroAmounts(
    address[] memory tokens,
    uint[] memory amounts
  ) internal pure returns (
    address[] memory t,
    uint[] memory a
  ) {
    require(tokens.length == amounts.length, AppErrors.INCORRECT_LENGTHS);
    uint len2 = 0;
    uint len = tokens.length;
    for (uint i = 0; i < len; i++) {
      if (amounts[i] != 0) len2++;
    }

    t = new address[](len2);
    a = new uint[](len2);

    uint j = 0;
    for (uint i = 0; i < len; i++) {
      uint amount = amounts[i];
      if (amount != 0) {
        t[j] = tokens[i];
        a[j] = amount;
        j++;
      }
    }
  }

  /// @notice unites three arrays to single array without duplicates, amounts are sum, zero amounts are allowed
  function combineArrays(
    address[] memory tokens0,
    uint[] memory amounts0,
    address[] memory tokens1,
    uint[] memory amounts1,
    address[] memory tokens2,
    uint[] memory amounts2
  ) internal pure returns (
    address[] memory allTokens,
    uint[] memory allAmounts
  ) {
    uint[] memory lens = new uint[](3);
    lens[0] = tokens0.length;
    lens[1] = tokens1.length;
    lens[2] = tokens2.length;

    require(
      lens[0] == amounts0.length && lens[1] == amounts1.length && lens[2] == amounts2.length,
      AppErrors.INCORRECT_LENGTHS
    );

    uint maxLength = lens[0] + lens[1] + lens[2];
    address[] memory tokensOut = new address[](maxLength);
    uint[] memory amountsOut = new uint[](maxLength);
    uint unitedLength;

    for (uint step; step < 3; ++step) {
      uint[] memory amounts = step == 0
        ? amounts0
        : (step == 1
          ? amounts1
          : amounts2);
      address[] memory tokens = step == 0
        ? tokens0
        : (step == 1
          ? tokens1
          : tokens2);
      for (uint i1 = 0; i1 < lens[step]; i1++) {
        uint amount1 = amounts[i1];
        address token1 = tokens[i1];
        bool united = false;

        for (uint i = 0; i < unitedLength; i++) {
          if (token1 == tokensOut[i]) {
            amountsOut[i] += amount1;
            united = true;
            break;
          }
        }

        if (!united) {
          tokensOut[unitedLength] = token1;
          amountsOut[unitedLength] = amount1;
          unitedLength++;
        }
      }
    }

    // copy united tokens to result array
    allTokens = new address[](unitedLength);
    allAmounts = new uint[](unitedLength);
    for (uint i; i < unitedLength; i++) {
      allTokens[i] = tokensOut[i];
      allAmounts[i] = amountsOut[i];
    }

  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20.sol";
import "@tetu_io/tetu-contracts-v2/contracts/interfaces/IERC20Metadata.sol";
import "@tetu_io/tetu-contracts-v2/contracts/openzeppelin/SafeERC20.sol";
import "../../libs/AppErrors.sol";
import "../../libs/AppLib.sol";
import "../../libs/TokenAmountsLib.sol";
import "../../integrations/balancer/IComposableStablePool.sol";
import "../../integrations/balancer/ILinearPool.sol";
import "../../integrations/balancer/IBVault.sol";
import "../../integrations/balancer/IBalancerHelper.sol";
import "../../integrations/balancer/IBalancerGauge.sol";

/// @notice Functions of BalancerBoostedDepositor
/// @dev Many of functions are declared as external to reduce contract size
library BalancerLogicLib {
  using SafeERC20 for IERC20;

  /////////////////////////////////////////////////////////////////////
  ///             Types
  /////////////////////////////////////////////////////////////////////

  /// @dev local vars in getAmountsToDeposit to avoid stack too deep
  struct LocalGetAmountsToDeposit {
    /// @notice Decimals of {tokens_}, 0 for BPT
    uint[] decimals;
    /// @notice Length of {tokens_} array
    uint len;
    /// @notice amountBPT / underlyingAmount, decimals 18, 0 for BPT
    uint[] rates;
  }

  /// @notice Local variables required inside _depositorEnter/Exit/QuoteExit, avoid stack too deep
  struct DepositorLocal {
    uint bptIndex;
    uint len;
    IERC20[] tokens;
    uint[] balances;
  }

  /// @notice Used in linear pool quote swap math logic
  struct LinearPoolParams {
    uint fee;
    uint lowerTarget;
    uint upperTarget;
  }

  /////////////////////////////////////////////////////////////////////
  ///             Asset related utils
  /////////////////////////////////////////////////////////////////////

  /// @notice Calculate amounts of {tokens} to be deposited to POOL_ID in proportions according to the {balances}
  /// @param amountsDesired_ Desired amounts of tokens. The order of the tokens is exactly the same as in {tokens}.
  ///                        But the array has length 3, not 4, because there is no amount for bb-am-USD here.
  /// @param tokens_ All bb-am-* tokens (including bb-am-USD) received through getPoolTokens
  ///                           The order of the tokens is exactly the same as in getPoolTokens-results
  /// @param balances_ Balances of bb-am-* pools in terms of bb-am-USD tokens (received through getPoolTokens)
  ///                           The order of the tokens is exactly the same as in {tokens}
  /// @param totalUnderlying_ Total amounts of underlying assets (DAI, USDC, etc) in embedded linear pools.
  ///                         The array should have same order of tokens as {tokens_}, value for BPT token is not used
  /// @param indexBpt_ Index of BPT token inside {balances_}, {tokens_} and {totalUnderlying_} arrays
  /// @return amountsOut Desired amounts in proper proportions for depositing.
  ///         The order of the tokens is exactly the same as in results of getPoolTokens, 0 for BPT
  ///         i.e. DAI, BB-AM-USD, USDC, USDT
  function getAmountsToDeposit(
    uint[] memory amountsDesired_,
    IERC20[] memory tokens_,
    uint[] memory balances_,
    uint[] memory totalUnderlying_,
    uint indexBpt_
  ) internal view returns (
    uint[] memory amountsOut
  ) {
    LocalGetAmountsToDeposit memory p;
    // check not zero balances, cache index of bbAmUSD, save 10**decimals to array
    p.len = tokens_.length;
    require(p.len == balances_.length, AppErrors.WRONG_LENGTHS);
    require(p.len == amountsDesired_.length || p.len - 1 == amountsDesired_.length, AppErrors.WRONG_LENGTHS);

    p.decimals = new uint[](p.len);
    p.rates = new uint[](p.len);
    for (uint i = 0; i < p.len; i = AppLib.uncheckedInc(i)) {
      if (i != indexBpt_) {
        require(balances_[i] != 0, AppErrors.ZERO_BALANCE);
        p.decimals[i] = 10 ** IERC20Metadata(address(tokens_[i])).decimals();

        // Let's calculate a rate: amountBPT / underlyingAmount, decimals 18
        p.rates[i] = balances_[i] * 1e18 / totalUnderlying_[i];
      }
    }

    amountsOut = new uint[](p.len - 1);

    // The balances set proportions of underlying-bpt, i.e. bb-am-DAI : bb-am-USDC : bb-am-USDT
    // Our task is find amounts of DAI : USDC : USDT that won't change that proportions after deposit.
    // We have arbitrary desired amounts, i.e. DAI = X, USDC = Y, USDT = Z
    // For each token: assume that it can be used in full.
    // If so, what amounts will have other tokens in this case according to the given proportions?
    // i.e. DAI = X = 100.0 => USDC = 200.0, USDT = 400.0. We need: Y >= 200, Z >= 400
    // or   USDC = Y = 100.0 => DAI = 50.0, USDT = 200.0. We need: X >= 50, Z >= 200
    // If any amount is less then expected, the token cannot be used in full.
    // A token with min amount can be used in full, let's try to find its index.
    // [0 : len - 1]
    uint i3;
    for (uint i; i < p.len; i = AppLib.uncheckedInc(i)) {
      if (indexBpt_ == i) continue;

      uint amountInBpt18 = amountsDesired_[i3] * p.rates[i];

      // [0 : len]
      uint j;
      // [0 : len - 1]
      uint j3;
      for (; j < p.len; j = AppLib.uncheckedInc(j)) {
        if (indexBpt_ == j) continue;

        // alpha = balancesDAI / balancesUSDC * decimalsDAI / decimalsUSDC
        // amountDAI = amountUSDC * alpha * rateUSDC / rateDAI
        amountsOut[j3] = amountInBpt18 * balances_[j] / p.rates[j] * p.decimals[j] / balances_[i] / p.decimals[i];
        if (amountsOut[j3] > amountsDesired_[j3]) break;
        j3++;
      }

      if (j == p.len) break;
      i3++;
    }
  }


  /// @notice Calculate total amount of underlying asset for each token except BPT
  /// @dev Amount is calculated as MainTokenAmount + WrappedTokenAmount * WrappedTokenRate, see AaveLinearPool src
  function getTotalAssetAmounts(IBVault vault_, IERC20[] memory tokens_, uint indexBpt_) internal view returns (
    uint[] memory amountsOut
  ) {
    uint len = tokens_.length;
    amountsOut = new uint[](len);
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i != indexBpt_) {
        ILinearPool linearPool = ILinearPool(address(tokens_[i]));
        (, uint[] memory balances,) = vault_.getPoolTokens(linearPool.getPoolId());

        amountsOut[i] =
        balances[linearPool.getMainIndex()]
        + balances[linearPool.getWrappedIndex()] * linearPool.getWrappedTokenRate() / 1e18;
      }
    }
  }

  /// @notice Split {liquidityAmount_} by assets according to proportions of their total balances
  /// @param liquidityAmount_ Amount to withdraw in bpt
  /// @param balances_ Balances received from getPoolTokens
  /// @param bptIndex_ Index of pool-pbt inside {balances_}
  /// @return bptAmountsOut Amounts of underlying-BPT. The array doesn't include an amount for pool-bpt
  ///         Total amount of {bptAmountsOut}-items is equal to {liquidityAmount_}
  function getBtpAmountsOut(
    uint liquidityAmount_,
    uint[] memory balances_,
    uint bptIndex_
  ) internal pure returns (uint[] memory bptAmountsOut) {
    // we assume here, that len >= 2
    // we don't check it because StableMath.sol in balancer has _MIN_TOKENS = 2;
    uint len = balances_.length;
    bptAmountsOut = new uint[](len - 1);

    // compute total balance, skip pool-bpt
    uint totalBalances;
    uint k;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == bptIndex_) continue;
      totalBalances += balances_[i];
      // temporary save incomplete amounts to bptAmountsOut
      bptAmountsOut[k] = liquidityAmount_ * balances_[i];
      ++k;
    }

    // finalize computation of bptAmountsOut using known totalBalances
    uint total;
    for (k = 0; k < len - 1; k = AppLib.uncheckedInc(k)) {
      if (k == len - 2) {
        // leftovers => last item
        bptAmountsOut[k] = total > liquidityAmount_
        ? 0
        : liquidityAmount_ - total;
      } else {
        bptAmountsOut[k] /= totalBalances;
        total += bptAmountsOut[k];
      }
    }
  }

  /////////////////////////////////////////////////////////////////////
  ///             Depositor view logic
  /////////////////////////////////////////////////////////////////////
  /// @notice Total amounts of the main assets under control of the pool, i.e amounts of USDT, USDC, DAI
  /// @return reservesOut Total amounts of embedded assets, i.e. for "Balancer Boosted Tetu USD" we return:
  ///                     0: balance USDT + (tUSDT recalculated to USDT)
  ///                     1: balance USDC + (tUSDC recalculated to USDC)
  ///                     2: balance DAI + (balance tDAI recalculated to DAI)
  function depositorPoolReserves(IBVault vault_, bytes32 poolId_) external view returns (uint[] memory reservesOut) {
    (IERC20[] memory tokens,,) = vault_.getPoolTokens(poolId_);
    uint bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();
    uint len = tokens.length;
    // exclude pool-BPT
    reservesOut = new uint[](len - 1);

    uint k;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == bptIndex) continue;
      ILinearPool linearPool = ILinearPool(address(tokens[i]));

      // Each bb-t-* returns (main-token, wrapped-token, bb-t-itself), the order of tokens is arbitrary
      // i.e. (DAI + tDAI + bb-t-DAI) or (bb-t-USDC, tUSDC, USDC)

      // get balances of all tokens of bb-am-XXX token, i.e. balances of (DAI, amDAI, bb-am-DAI)
      (, uint[] memory balances,) = vault_.getPoolTokens(linearPool.getPoolId());
      // DAI
      uint mainIndex = linearPool.getMainIndex();
      // tDAI
      uint wrappedIndex = linearPool.getWrappedIndex();

      reservesOut[k] = balances[mainIndex] + balances[wrappedIndex] * linearPool.getWrappedTokenRate() / 1e18;
      ++k;
    }
  }

  /// @notice Returns pool assets, same as getPoolTokens but without pool-bpt
  function depositorPoolAssets(IBVault vault_, bytes32 poolId_) external view returns (address[] memory poolAssets) {
    (IERC20[] memory tokens,,) = vault_.getPoolTokens(poolId_);
    uint bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();
    uint len = tokens.length;

    poolAssets = new address[](len - 1);
    uint k;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i == bptIndex) continue;

      poolAssets[k] = ILinearPool(address(tokens[i])).getMainToken();
      ++k;
    }
  }

  /// @notice Returns pool weights
  /// @return weights Array with weights, length = getPoolTokens.tokens - 1 (all assets except BPT)
  /// @return totalWeight Total sum of all items of {weights}
  function depositorPoolWeights(IBVault vault_, bytes32 poolId_) external view returns (
    uint[] memory weights,
    uint totalWeight
  ) {
    (IERC20[] memory tokens,uint[] memory balances,) = vault_.getPoolTokens(poolId_);
    uint len = tokens.length;
    uint bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();
    weights = new uint[](len - 1);
    uint j;
    for (uint i; i < len; i = AppLib.uncheckedInc(i)) {
      if (i != bptIndex) {
        totalWeight += balances[i];
        weights[j] = balances[i];
        j = AppLib.uncheckedInc(j);
      }
    }
  }

  /////////////////////////////////////////////////////////////////////
  ///             Depositor enter, exit logic
  /////////////////////////////////////////////////////////////////////
  /// @notice Deposit given amount to the pool.
  /// @param amountsDesired_ Amounts of assets on the balance of the depositor
  ///         The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  ///         i.e. for "Balancer Boosted Aave USD" we have DAI, USDC, USDT
  /// @return amountsConsumedOut Amounts of assets deposited to balanceR pool
  ///         The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  /// @return liquidityOut Total amount of liquidity added to balanceR pool in terms of pool-bpt tokens
  function depositorEnter(IBVault vault_, bytes32 poolId_, uint[] memory amountsDesired_) external returns (
    uint[] memory amountsConsumedOut,
    uint liquidityOut
  ) {
    DepositorLocal memory p;

    // The implementation below assumes, that getPoolTokens returns the assets in following order:
    //    bb-am-dai, bb-am-usd, bb-am-usdc, bb-am-usdt
    (p.tokens, p.balances,) = vault_.getPoolTokens(poolId_);
    p.len = p.tokens.length;
    p.bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();

    // temporary save current liquidity
    liquidityOut = IComposableStablePool(address(p.tokens[p.bptIndex])).balanceOf(address(this));

    // Original amounts can have any values.
    // But we need amounts in such proportions that won't move the current balances
    {
      uint[] memory underlying = BalancerLogicLib.getTotalAssetAmounts(vault_, p.tokens, p.bptIndex);
      amountsConsumedOut = BalancerLogicLib.getAmountsToDeposit(amountsDesired_, p.tokens, p.balances, underlying, p.bptIndex);
    }

    // we can create funds_ once and use it several times
    IBVault.FundManagement memory funds = IBVault.FundManagement({
      sender : address(this),
      fromInternalBalance : false,
      recipient : payable(address(this)),
      toInternalBalance : false
    });

    // swap all tokens XX => bb-am-XX
    // we need two arrays with same amounts: amountsToDeposit (with 0 for BB-AM-USD) and userDataAmounts (no BB-AM-USD)
    uint[] memory amountsToDeposit = new uint[](p.len);
    // no bpt
    uint[] memory userDataAmounts = new uint[](p.len - 1);
    uint k;
    for (uint i; i < p.len; i = AppLib.uncheckedInc(i)) {
      if (i == p.bptIndex) continue;
      amountsToDeposit[i] = BalancerLogicLib.swap(
        vault_,
        ILinearPool(address(p.tokens[i])).getPoolId(),
        ILinearPool(address(p.tokens[i])).getMainToken(),
        address(p.tokens[i]),
        amountsConsumedOut[k],
        funds
      );
      userDataAmounts[k] = amountsToDeposit[i];
      AppLib.approveIfNeeded(address(p.tokens[i]), amountsToDeposit[i], address(vault_));
      ++k;
    }

    // add liquidity to balancer
    vault_.joinPool(
      poolId_,
      address(this),
      address(this),
      IBVault.JoinPoolRequest({
        assets : asIAsset(p.tokens), // must have the same length and order as the array returned by `getPoolTokens`
        maxAmountsIn : amountsToDeposit,
        userData : abi.encode(IBVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, userDataAmounts, 0),
        fromInternalBalance : false
      })
    );

    uint liquidityAfter = IERC20(address(p.tokens[p.bptIndex])).balanceOf(address(this));

    liquidityOut = liquidityAfter > liquidityOut
    ? liquidityAfter - liquidityOut
    : 0;
  }

  /// @notice Withdraw given amount of LP-tokens from the pool.
  /// @param liquidityAmount_ Amount to withdraw in bpt
  /// @return amountsOut Result amounts of underlying (DAI, USDC..) that will be received from BalanceR
  ///         The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  function depositorExit(IBVault vault_, bytes32 poolId_, uint liquidityAmount_) external returns (
    uint[] memory amountsOut
  ) {
    DepositorLocal memory p;

    p.bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();
    (p.tokens, p.balances,) = vault_.getPoolTokens(poolId_);
    p.len = p.tokens.length;

    require(liquidityAmount_ <= p.tokens[p.bptIndex].balanceOf(address(this)), AppErrors.NOT_ENOUGH_BALANCE);

    // BalancerR can spend a bit less amount of liquidity than {liquidityAmount_}
    // i.e. we if liquidityAmount_ = 2875841, we can have leftovers = 494 after exit
    vault_.exitPool(
      poolId_,
      address(this),
      payable(address(this)),
      IBVault.ExitPoolRequest({
        assets : asIAsset(p.tokens), // must have the same length and order as the array returned by `getPoolTokens`
        minAmountsOut : new uint[](p.len), // no limits
        userData : abi.encode(IBVault.ExitKindComposableStable.EXACT_BPT_IN_FOR_ALL_TOKENS_OUT, liquidityAmount_),
        toInternalBalance : false
      })
    );

    // now we have amBbXXX tokens; swap them to XXX assets

    // we can create funds_ once and use it several times
    IBVault.FundManagement memory funds = IBVault.FundManagement({
    sender : address(this),
    fromInternalBalance : false,
    recipient : payable(address(this)),
    toInternalBalance : false
    });

    amountsOut = new uint[](p.len - 1);
    uint k;
    for (uint i; i < p.len; i = AppLib.uncheckedInc(i)) {
      if (i == p.bptIndex) continue;
      uint amountIn = p.tokens[i].balanceOf(address(this));
      if (amountIn != 0) {
        amountsOut[k] = swap(
          vault_,
          ILinearPool(address(p.tokens[i])).getPoolId(),
          address(p.tokens[i]),
          ILinearPool(address(p.tokens[i])).getMainToken(),
          amountIn,
          funds
        );
      }
      ++k;
    }
  }

  /// @notice Withdraw all available amount of LP-tokens from the pool
  ///         BalanceR doesn't allow to withdraw exact amount, so it's allowed to leave dust amount on the balance
  /// @dev We make at most N attempts to withdraw (not more, each attempt takes a lot of gas).
  ///      Each attempt reduces available balance at ~1e4 times.
  /// @return amountsOut Result amounts of underlying (DAI, USDC..) that will be received from BalanceR
  ///                    The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  function depositorExitFull(IBVault vault_, bytes32 poolId_) external returns (
    uint[] memory amountsOut
  ) {
    DepositorLocal memory p;

    p.bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();
    (p.tokens, p.balances,) = vault_.getPoolTokens(poolId_);
    p.len = p.tokens.length;
    amountsOut = new uint[](p.len - 1);

    // we can create funds_ once and use it several times
    IBVault.FundManagement memory funds = IBVault.FundManagement({
      sender : address(this),
      fromInternalBalance : false,
      recipient : payable(address(this)),
      toInternalBalance : false
    });

    uint liquidityAmount = p.tokens[p.bptIndex].balanceOf(address(this));
    if (liquidityAmount > 0) {
      uint liquidityThreshold = 10 ** IERC20Metadata(address(p.tokens[p.bptIndex])).decimals() / 100;

      // we can make at most N attempts to withdraw amounts from the balanceR pool
      for (uint i = 0; i < 2; ++i) {
        vault_.exitPool(
          poolId_,
          address(this),
          payable(address(this)),
          IBVault.ExitPoolRequest({
            assets : asIAsset(p.tokens),
            minAmountsOut : new uint[](p.len), // no limits
            userData : abi.encode(IBVault.ExitKindComposableStable.EXACT_BPT_IN_FOR_ALL_TOKENS_OUT, liquidityAmount),
            toInternalBalance : false
          })
        );
        liquidityAmount = p.tokens[p.bptIndex].balanceOf(address(this));
        if (liquidityAmount < liquidityThreshold || i == 1) {
          break;
        }
        (, p.balances,) = vault_.getPoolTokens(poolId_);
      }

      // now we have amBbXXX tokens; swap them to XXX assets
      uint k;
      for (uint i; i < p.len; i = AppLib.uncheckedInc(i)) {
        if (i == p.bptIndex) continue;

        uint amountIn = p.tokens[i].balanceOf(address(this));
        if (amountIn != 0) {
          amountsOut[k] = swap(
            vault_,
            ILinearPool(address(p.tokens[i])).getPoolId(),
            address(p.tokens[i]),
            ILinearPool(address(p.tokens[i])).getMainToken(),
            amountIn,
            funds
          );
        }
        ++k;
      }
    }

    uint depositorBalance = p.tokens[p.bptIndex].balanceOf(address(this));
    if (depositorBalance > 0) {
      uint k = 0;
      for (uint i; i < p.len; i = AppLib.uncheckedInc(i)) {
        if (i == p.bptIndex) continue;

        // we assume here, that the depositorBalance is small
        // so we can directly swap it to any single asset without changing of pool resources proportions
        amountsOut[k] += _convertSmallBptRemainder(vault_, poolId_, p, funds, depositorBalance, i);
        break;
      }
    }

    return amountsOut;
  }

  /// @notice convert remained SMALL amount of bpt => am-bpt => main token of the am-bpt
  /// @return amountOut Received amount of am-bpt's main token
  function _convertSmallBptRemainder(
    IBVault vault_,
    bytes32 poolId_,
    DepositorLocal memory p,
    IBVault.FundManagement memory funds,
    uint bptAmountIn_,
    uint indexTargetAmBpt_
  ) internal returns (uint amountOut) {
    uint amountAmBpt = BalancerLogicLib.swap(
      vault_,
      poolId_,
      address(p.tokens[p.bptIndex]),
      address(p.tokens[indexTargetAmBpt_]),
      bptAmountIn_,
      funds
    );
    amountOut = swap(
      vault_,
      ILinearPool(address(p.tokens[indexTargetAmBpt_])).getPoolId(),
      address(p.tokens[indexTargetAmBpt_]),
      ILinearPool(address(p.tokens[indexTargetAmBpt_])).getMainToken(),
      amountAmBpt,
      funds
    );
  }

  /// @notice Quotes output for given amount of LP-tokens from the pool.
  /// @return amountsOut Result amounts of underlying (DAI, USDC..) that will be received from BalanceR
  ///         The order of assets is the same as in getPoolTokens, but there is no pool-bpt
  function depositorQuoteExit(
    IBVault vault_,
    IBalancerHelper helper_,
    bytes32 poolId_,
    uint liquidityAmount_
  ) external returns (
    uint[] memory amountsOut
  ) {
    DepositorLocal memory p;

    p.bptIndex = IComposableStablePool(getPoolAddress(poolId_)).getBptIndex();
    (p.tokens, p.balances,) = vault_.getPoolTokens(poolId_);
    p.len = p.tokens.length;

    (, uint[] memory amountsBpt) = helper_.queryExit(
      poolId_,
      address(this),
      payable(address(this)),
      IBVault.ExitPoolRequest({
        assets : asIAsset(p.tokens),
        minAmountsOut : new uint[](p.len), // no limits
        userData : abi.encode(
          IBVault.ExitKindComposableStable.EXACT_BPT_IN_FOR_ALL_TOKENS_OUT,
          liquidityAmount_
        ),
        toInternalBalance : false
      })
    );

    uint k;
    amountsOut = new uint[](p.len - 1);
    for (uint i = 0; i < p.len; i = AppLib.uncheckedInc(i)) {
      if (i == p.bptIndex) continue;
      ILinearPool linearPool = ILinearPool(address(p.tokens[i]));
      amountsOut[k] = _calcLinearMainOutPerBptIn(vault_, linearPool, amountsBpt[i]);
      ++k;
    }
  }

  /// @notice Swap given {amountIn_} of {assetIn_} to {assetOut_} using the given BalanceR pool
  function swap(
    IBVault vault_,
    bytes32 poolId_,
    address assetIn_,
    address assetOut_,
    uint amountIn_,
    IBVault.FundManagement memory funds_
  ) internal returns (uint amountOut) {
    uint balanceBefore = IERC20(assetOut_).balanceOf(address(this));

    IERC20(assetIn_).approve(address(vault_), amountIn_);
    vault_.swap(
      IBVault.SingleSwap({
    poolId : poolId_,
    kind : IBVault.SwapKind.GIVEN_IN,
    assetIn : IAsset(assetIn_),
    assetOut : IAsset(assetOut_),
    amount : amountIn_,
    userData : bytes("")
    }),
      funds_,
      1,
      block.timestamp
    );

    // we assume here, that the balance cannot be decreased
    amountOut = IERC20(assetOut_).balanceOf(address(this)) - balanceBefore;
  }

  /////////////////////////////////////////////////////////////////////
  ///             Rewards
  /////////////////////////////////////////////////////////////////////

  function depositorClaimRewards(IBalancerGauge gauge_, address[] memory tokens_, address[] memory rewardTokens_) external returns (
    address[] memory tokensOut,
    uint[] memory amountsOut,
    uint[] memory depositorBalancesBefore
  ) {
    uint tokensLen = tokens_.length;
    uint rewardTokensLen = rewardTokens_.length;

    tokensOut = new address[](rewardTokensLen);
    amountsOut = new uint[](rewardTokensLen);
    depositorBalancesBefore = new uint[](tokensLen);

    for (uint i; i < tokensLen; i = AppLib.uncheckedInc(i)) {
      depositorBalancesBefore[i] = IERC20(tokens_[i]).balanceOf(address(this));
    }

    for (uint i; i < rewardTokensLen; i = AppLib.uncheckedInc(i)) {
      tokensOut[i] = rewardTokens_[i];

      // temporary store current reward balance
      amountsOut[i] = IERC20(rewardTokens_[i]).balanceOf(address(this));
    }

    gauge_.claim_rewards();

    for (uint i; i < rewardTokensLen; i = AppLib.uncheckedInc(i)) {
      amountsOut[i] = IERC20(rewardTokens_[i]).balanceOf(address(this)) - amountsOut[i];
    }

    (tokensOut, amountsOut) = TokenAmountsLib.filterZeroAmounts(tokensOut, amountsOut);
  }

  /////////////////////////////////////////////////////////////////////
  ///             Utils
  /////////////////////////////////////////////////////////////////////

  function createSpecificName(address pool_) external view returns (string memory) {
    return string(abi.encodePacked("Balancer ", IERC20Metadata(pool_).symbol()));
  }

  /// @dev Returns the address of a Pool's contract.
  ///      Due to how Pool IDs are created, this is done with no storage accesses and costs little gas.
  function getPoolAddress(bytes32 id) internal pure returns (address) {
    // 12 byte logical shift left to remove the nonce and specialization setting. We don't need to mask,
    // since the logical shift already sets the upper bits to zero.
    return address(uint160(uint(id) >> (12 * 8)));
  }

  /// @dev see balancer-labs, ERC20Helpers.sol
  function asIAsset(IERC20[] memory tokens) internal pure returns (IAsset[] memory assets) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      assets := tokens
    }
  }

  /////////////////////////////////////////////////////////////////////
  ///             Linear pool quote swap math logic
  /////////////////////////////////////////////////////////////////////

  /// @dev This logic is needed for hardworks in conditions of lack of funds in linear pools.
  ///      The lack of funds in linear pools is a typical situation caused by pool rebalancing after deposits from the strategy.
  ///      Main tokens are leaving linear pools to mint wrapped tokens.
  function _calcLinearMainOutPerBptIn(IBVault vault, ILinearPool pool, uint amount) internal view returns (uint) {
    (uint lowerTarget, uint upperTarget) = pool.getTargets();
    LinearPoolParams memory params = LinearPoolParams(pool.getSwapFeePercentage(), lowerTarget, upperTarget);
    (,uint[] memory balances,) = vault.getPoolTokens(pool.getPoolId());
    uint[] memory scalingFactors = pool.getScalingFactors();
    _upscaleArray(balances, scalingFactors);
    amount *= scalingFactors[0] / 1e18;
    uint mainIndex = pool.getMainIndex();
    uint mainBalance = balances[mainIndex];
    uint bptSupply = pool.totalSupply() - balances[0];
    uint previousNominalMain = _toNominal(mainBalance, params);
    uint invariant = previousNominalMain + balances[pool.getWrappedIndex()];
    uint deltaNominalMain = invariant * amount / bptSupply;
    uint afterNominalMain = previousNominalMain > deltaNominalMain ? previousNominalMain - deltaNominalMain : 0;
    uint newMainBalance = _fromNominal(afterNominalMain, params);
    return (mainBalance - newMainBalance) * 1e18 / scalingFactors[mainIndex];
  }

  function _toNominal(uint real, LinearPoolParams memory params) internal pure returns (uint) {
    if (real < params.lowerTarget) {
      uint fees = (params.lowerTarget - real) * params.fee / 1e18;
      return real - fees;
    } else if (real <= params.upperTarget) {
      return real;
    } else {
      uint fees = (real - params.upperTarget) * params.fee / 1e18;
      return real - fees;
    }
  }

  function _fromNominal(uint nominal, LinearPoolParams memory params) internal pure returns (uint) {
    if (nominal < params.lowerTarget) {
      return (nominal + (params.fee * params.lowerTarget / 1e18)) * 1e18 / (1e18 + params.fee);
    } else if (nominal <= params.upperTarget) {
      return nominal;
    } else {
      return (nominal - (params.fee * params.upperTarget / 1e18)) * 1e18/ (1e18 - params.fee);
    }
  }

  function _upscaleArray(uint[] memory amounts, uint[] memory scalingFactors) internal pure {
    uint length = amounts.length;
    for (uint i; i < length; ++i) {
      amounts[i] = amounts[i] * scalingFactors[i] / 1e18;
    }
  }
}