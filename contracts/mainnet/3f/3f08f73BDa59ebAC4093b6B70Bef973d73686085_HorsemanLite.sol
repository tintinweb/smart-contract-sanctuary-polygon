/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// File: IBankroll.sol



pragma solidity ^0.8.0;

interface IBankroll {
    function isAdminAddr(address addr) external view returns (bool);
    function getNumPay() external view returns (uint256);
    function payPlayer(address addr, uint256 val) external;

    function addPayAddrTemp(address _addr, uint256 _val) external;

    function payAddrTempByAddr(address _addr) external;
    function getDataTempByAddr(address _addr) external view  returns (uint256);

    function addVRFFees(uint256 val) external;
    function addEcosystem(uint256 val) external;
}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
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

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// File: HorsemanLite.sol


pragma solidity ^0.8.0;






interface IVRFCoordinatorV2 is VRFCoordinatorV2Interface {
    function getFeeConfig()
        external
        view
        returns (
            uint32,
            uint32,
            uint32,
            uint32,
            uint32,
            uint24,
            uint24,
            uint24,
            uint24
        );
}

contract HorsemanLite is ReentrancyGuard {
    using SafeERC20 for IERC20;
    ////////////////////////////////////////////// constant ////////////////////////////////////////////////////////////

    uint256 private constant RoundTime = 259200;
    uint256 private constant MaxTime = 259200;
    uint256 private constant AddTime = 60;
    uint256 public constant HeroPrice = 10 ether;

    uint256 private constant CntDivide = 10000;
    uint256 private constant Ecosystem = 150;
    uint256 private constant GrandPot = 150;
    uint256[4] private Dividend = [1000, 10, 100, 300]; //[init, 0.1%update, drop1%, min3%]

    uint256[5] private Probability = [9950, 9750, 8750, 6750, 2950];
    uint256[5] private Multiplier = [3000, 600, 300, 158, 30];

    uint256 private constant MaxMul = 125;
    uint256 private constant MinMul = 36;
    ////////////////////////////////////////////// var ////////////////////////////////////////////////////////////
    uint256 public roundIndex;
    uint256 public curDividend;
    mapping(uint256 => Round) mapRound; //(roundId => Round)
    mapping(uint256 => mapping(address => DataPlay)) mapPlay; //(rountId => (address => DataPlay))
    address[] public arrAddr;
    mapping(address => uint256) mapDefeatCnt;

    mapping(uint256 => address) mapRandomId; //(RandomId => address)
    mapping(address => DataRandom) mapRandomData; //(address => DataRandom)

    AggregatorV3Interface public LINK_ETH_FEED;
    IVRFCoordinatorV2 public IChainLinkVRF;
    address public ChainLinkVRF;
    IBankroll public Bankroll;

    address public KeeperConsumer;

    constructor(
        IBankroll _Bankroll,
        address _vrf,
        address _link_eth_feed
    ) {
        Bankroll = _Bankroll;
        IChainLinkVRF = IVRFCoordinatorV2(_vrf);
        LINK_ETH_FEED = AggregatorV3Interface(_link_eth_feed);
        ChainLinkVRF = _vrf;
        startGame();
    }

    modifier isActivated() {
        require(activated_ == true, "its not ready yet");
        _;
    }

    modifier isInTime() {
        require(
            mapRound[roundIndex].endTime == 0 ||
                mapRound[roundIndex].endTime > block.timestamp,
            "game is over"
        );
        _;
    }

    /**
     * @dev prevents contracts from interacting with game
     */
    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;

        assembly {
            _codeLength := extcodesize(_addr)
        }
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    /**
     * @dev sets boundaries for incoming tx
     */
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "min error");
        require(_eth <= 100000000000000000000000, "max error");
        _;
    }

    modifier isAdmin() {
        require(Bankroll.isAdminAddr(msg.sender), "Admin Only");
        _;
    }

    /**
     * @dev Duel
     * @param wager wager amount
     * @param _tokenAddress address of token to bet, 0 address is considered the native coin
     */
    function Duel(address _tokenAddress, uint256 wager)
        external
        payable
        isActivated
        isInTime
        isHuman
        isWithinLimits(msg.value)
        nonReentrant
    {
        if (
            wager < HeroPrice || msg.value < wager || wager > MaxMul * HeroPrice
        ) {
            revert InvalidValue(wager, msg.value);
        }
        if (mapRandomData[msg.sender].id != 0) {
            revert AwaitingVRF(mapRandomData[msg.sender].id);
        }
        address tokenAddress = 0x0000000000000000000000000000000000000000;
        _kellyWager(wager, tokenAddress);
        _transferWager(tokenAddress, wager, 1000000);

        uint256 id = _requestRandomWords(1);
        mapRandomData[msg.sender] = DataRandom(
            id,
            wager,
            tokenAddress,
            uint64(block.number)
        );
        mapRandomId[id] = msg.sender;
    }

    /**
     * @dev Function to refund user in case of VRF request failling
     */
    function Duel_Refund() external isHuman nonReentrant {
        DataRandom storage dataRandom = mapRandomData[msg.sender];
        if (dataRandom.id == 0) {
            revert NotAwaitingVRF();
        }
        if (dataRandom.blockNumber + 200 > block.number) {
            revert BlockNumberTooLow(
                block.number,
                dataRandom.blockNumber + 200
            );
        }

        uint256 wager = dataRandom.wager;
        address tokenAddress = dataRandom.tokenAddress;

        delete (mapRandomId[dataRandom.id]);
        delete (mapRandomData[msg.sender]);

        if (tokenAddress == address(0)) {
            (bool success, ) = payable(msg.sender).call{value: wager}("");
            if (!success) {
                revert TransferFailed();
            }
        } else {
            IERC20(tokenAddress).safeTransfer(msg.sender, wager);
        }
        emit Duel_Refund_Event(msg.sender, wager, tokenAddress);
    }

    /**
     * @dev function called by Chainlink VRF with random numbers
     * @param requestId id provided when the request was made
     * @param randomWords array of random numbers
     */
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != ChainLinkVRF) {
            revert OnlyCoordinatorCanFulfill(msg.sender, ChainLinkVRF);
        }
        fulfillRandomWords(requestId, randomWords);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
    {
        address addr = mapRandomId[requestId];
        if (addr == address(0)) revert();

        Round storage round = mapRound[roundIndex];
        DataPlay storage play = mapPlay[roundIndex][addr];
        DataRandom storage dataRandom = mapRandomData[addr];

        uint256 r = randomWords[0] % 10000;

        if (curDividend > Dividend[3]) {
            uint256 r2 = (randomWords[0] / 10000) % 10000;
            if (r2 <= Dividend[1]) {
                curDividend -= Dividend[2];
                if (curDividend < Dividend[3]) {
                    curDividend = Dividend[3];
                }
            }
        }

        GameResultType resultType;
        uint256 reward = 0;

        if (r >= Probability[0]) {
            resultType = GameResultType.Rugpulled;
            reward = (Multiplier[0] * dataRandom.wager) / 100;

            round.addr = addr;
            round.endTime = block.timestamp + RoundTime;
        } else if (r >= Probability[1]) {
            resultType = GameResultType.Steamrolled;
            reward = (Multiplier[1] * dataRandom.wager) / 100;
        } else if (r >= Probability[2]) {
            resultType = GameResultType.OverKill;
            reward = (Multiplier[2] * dataRandom.wager) / 100;
        } else if (r >= Probability[3]) {
            resultType = GameResultType.Win;
            reward = (Multiplier[3] * dataRandom.wager) / 100;
		} else if(r >= Probability[4]){
            resultType = GameResultType.Tie;
            reward = (Multiplier[4] * dataRandom.wager) / 100;
        } else {
            resultType = GameResultType.Lose;
        }

        if(round.addr == address(0)){
            round.addr = addr;
        }

       // first time
        if (round.endTime == 0) {
		    for (uint256 i = 0; i < arrAddr.length; i++) {
                delete mapDefeatCnt[arrAddr[i]];
            }
            delete arrAddr;
            round.endTime = block.timestamp + RoundTime;
        }

        DataIncome memory income;
        play.wager += dataRandom.wager;
        play.lastResultType = resultType;
        if (reward == 0) {
            uint256 defeatCnt = dataRandom.wager / HeroPrice;
            play.defeat += defeatCnt;
            round.defeatCnt += defeatCnt;

            if (mapDefeatCnt[addr] == 0) {
                arrAddr.push(addr);
            }
            mapDefeatCnt[addr] += defeatCnt;
        } else {		
            uint256 unit = reward / CntDivide;

            DataInfo memory data = DataInfo(
                unit * Ecosystem,
                unit * GrandPot,
                round.defeatCnt > 0 ? unit * curDividend : 0
            );

            round.bounty += data.bounty;
            round.curDividend = curDividend;

            //transfer dividend
            if (round.defeatCnt > 0) {
                uint256 unitDividend = data.dividend / round.defeatCnt;
                for (uint256 i = 0; i < arrAddr.length; i++) {
                    address _addr = arrAddr[i];
                    if (mapDefeatCnt[_addr] > 0) {
                        uint256 _dividend = unitDividend * mapDefeatCnt[_addr];
                        Bankroll.addPayAddrTemp(_addr, _dividend);
                    }
                    //client need sync
                    if (mapPlay[roundIndex][_addr].defeat > 0) {
                        uint256 _dividend2 = unitDividend *
                            mapPlay[roundIndex][_addr].defeat;
                        mapPlay[roundIndex][_addr].dividend += _dividend2;
                    }
                }
            }

            reward = reward - data.ecosystem - data.bounty - data.dividend;
            play.wining += reward;

            //transfer ecosystem
            Bankroll.addEcosystem(data.ecosystem);
            //transfer reward
            Bankroll.addPayAddrTemp(addr, reward);

            income = DataIncome(
                dataRandom.wager,
                reward,
                data.ecosystem,
                data.bounty,
                data.dividend
            );
        }

        _transferToBankroll(dataRandom.tokenAddress, dataRandom.wager);
        round.balance = getBankBalance(dataRandom.tokenAddress);
        emit Duel_Outcome_Event(addr, play, round, income);

        delete (mapRandomId[requestId]);
        delete (mapRandomData[addr]);
    }

    //init data
    function startGame() private {
        roundIndex += 1;
        curDividend = Dividend[0];
    }

    function gameOver() external {
        if (msg.sender != KeeperConsumer && !Bankroll.isAdminAddr(msg.sender)) {
            revert OnlyKeeperConsumer(msg.sender, KeeperConsumer);
        }
        Round storage round = mapRound[roundIndex];
        require(block.timestamp > round.endTime, "no over");

        if (round.addr != address(0)) {
            Bankroll.payPlayer(round.addr, round.bounty);
        }

        startGame();
        emit GameOver_Event();
    }

    //on-off
    bool public activated_ = false;
    uint256 private timeRemaining;

    function activate() external {
        // only team just can activate
        require(
            Bankroll.isAdminAddr(msg.sender),
            "only team just can activate"
        );
        if (activated_) {
            if (mapRound[roundIndex].endTime > 0) {
                timeRemaining = mapRound[roundIndex].endTime - block.timestamp;
                mapRound[roundIndex].endTime = 0;
            }
        } else {
            if (timeRemaining > 0) {
                mapRound[roundIndex].endTime = block.timestamp + timeRemaining;
            }
        }

        activated_ = !activated_;
    }

    function _kellyWager(uint256 wager, address tokenAddress) private view {
        uint256 maxWager = getBankBalance(tokenAddress) / MinMul;

        if (wager > maxWager) {
            revert WagerAboveLimit(wager, maxWager);
        }
    }

    /**
     * @dev vrf fee
     * @param tokenAddress address of the token the wager is made on
     * @param wager total amount wagered
     */
    function _transferWager(
        address tokenAddress,
        uint256 wager,
        uint256 gasAmount
    ) private {
        if (wager == 0) {
            revert ZeroWager();
        }
        uint256 VRFfee = getVRFFee(gasAmount);

        if (tokenAddress == address(0)) {
            if (msg.value < wager + VRFfee) {
                revert InvalidValue(wager + VRFfee, msg.value);
            }
            _refundExcessValue(msg.value - (VRFfee + wager));
        } else {
            if (msg.value < VRFfee) {
                revert InvalidValue(VRFfee, msg.value);
            }
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                wager
            );
            _refundExcessValue(msg.value - VRFfee);
        }

        _transferToBankroll(tokenAddress, VRFfee);
        Bankroll.addVRFFees(VRFfee);
    }

    function _transferToBankroll(address tokenAddress, uint256 amount) private {
        if (tokenAddress == address(0)) {
            (bool success, ) = payable(address(Bankroll)).call{value: amount}(
                ""
            );
            if (!success) {
                revert RefundFailed();
            }
        } else {
            IERC20(tokenAddress).safeTransfer(address(Bankroll), amount);
        }
    }

    /**
     * @dev calculates in form of native token the fee charged by chainlink VRF
     * @return fee amount of fee user has to pay
     */
    function getVRFFee(uint256 gasAmount) public view returns (uint256 fee) {
        (, int256 answer, , , ) = LINK_ETH_FEED.latestRoundData();
        (uint32 fulfillmentFlatFeeLinkPPMTier1, , , , , , , , ) = IChainLinkVRF
            .getFeeConfig();

        fee =
            tx.gasprice *
            (gasAmount) +
            ((1e12 *
                uint256(fulfillmentFlatFeeLinkPPMTier1) *
                uint256(answer)) / 1e18);
    }

    /**
     * @dev returns to user the excess fee sent to pay for the VRF
     * @param refund amount to send back to user
     */
    function _refundExcessValue(uint256 refund) internal {
        if (refund == 0) {
            return;
        }
        (bool success, ) = payable(msg.sender).call{value: refund}("");
        if (!success) {
            revert RefundFailed();
        }
    }

    /**
     * @dev function to send the request for randomness to chainlink
     * @param numWords number of random numbers required
     */
    function _requestRandomWords(uint32 numWords)
        private
        returns (uint256 s_requestId)
    {
        s_requestId = VRFCoordinatorV2Interface(ChainLinkVRF)
            .requestRandomWords(
                0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8,
                809,
                3,
                2500000,
                numWords
            );
    }

    ////////////////////////////////////////////// struct////////////////////////////////////////////////////////////

    enum GameResultType {
        Lose,
		Tie,
        Win,
        OverKill,
        Steamrolled,
        Rugpulled
    }

    struct Round {
        uint256 endTime;
        uint256 bounty;
        uint256 defeatCnt;
        address addr;
        uint256 balance;
        uint256 curDividend;
    }

    struct DataPlay {
        uint256 wager;
        uint256 wining;
        uint256 dividend;
        uint256 defeat;
        GameResultType lastResultType;
    }

    struct DataIncome {
        uint256 wager;
        uint256 reward;
        uint256 ecosystem;
        uint256 grandPot;
        uint256 dividend;
    }

    struct DataRandom {
        uint256 id;
        uint256 wager;
        address tokenAddress;
        uint64 blockNumber;
    }

    struct DataInfo {
        uint256 ecosystem;
        uint256 bounty;
        uint256 dividend;
    }

    ////////////////////////////////////////////// event ////////////////////////////////////////////////////////////
    event Duel_Outcome_Event(
        address indexed player,
        DataPlay dataPlay,
        Round round,
        DataIncome income
    );

    event Duel_Refund_Event(
        address indexed player,
        uint256 wager,
        address tokenAddress
    );

    event GameOver_Event();
    ////////////////////////////////////////////// error ////////////////////////////////////////////////////////////
    error AwaitingVRF(uint256 requestID);
    error WagerAboveLimit(uint256 wager, uint256 maxWager);
    error NotAwaitingVRF();
    error BlockNumberTooLow(uint256 have, uint256 want);
    error TransferFailed();
    error InvalidValue(uint256 required, uint256 sent);
    error RefundFailed();
    error ZeroWager();
    error OnlyCoordinatorCanFulfill(address have, address want);
    error OnlyKeeperConsumer(address have, address want);

    ////////////////////////////////////////////// external ////////////////////////////////////////////////////////////
    function upkeepNeeded() external view returns (bool) {
        uint256 endTime = mapRound[roundIndex].endTime;
        return endTime > 0 && endTime <= block.timestamp;
    }

    function setKeeperConsumer(address _KeeperConsumer) external isAdmin {
        KeeperConsumer = _KeeperConsumer;
    }

    function getRound() external view returns (Round memory) {
        return mapRound[roundIndex];
    }

    function getDataPlayer() external view returns (DataPlay memory) {
        return mapPlay[roundIndex][msg.sender];
    }

    function getMultiplier() external view returns (uint256[5] memory) {
        return Multiplier;
    }

    function getProbability() external view returns (uint256[5] memory) {
        return Probability;
    }

    function payAddrTempByAddr() external isHuman {
        Bankroll.payAddrTempByAddr(msg.sender);
    }

    function getDataTempByAddr() external view returns (uint256) {
        return Bankroll.getDataTempByAddr(msg.sender);
    }

    function getBankBalance(address _tokenAddress)
        public
        view
        returns (uint256)
    {
        uint256 balance;
        address tokenAddress = 0x0000000000000000000000000000000000000000;
        if (tokenAddress == address(0)) {
            balance = address(Bankroll).balance;
        } else {
            balance = IERC20(tokenAddress).balanceOf(address(Bankroll));
        }
        uint256 bankBalance = balance -
            Bankroll.getNumPay() -
            mapRound[roundIndex].bounty;
        return bankBalance;
    }
}