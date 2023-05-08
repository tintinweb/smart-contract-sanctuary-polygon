// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Vault.sol";

contract LottoGame is VRFConsumerBaseV2 {
    struct Ticket {
        uint8 num1;
        uint8 num2;
        uint8 num3;
        uint8 num4;
        uint8 num5;
        uint8 joker;
    }

    enum Status {
        Open,
        Closed
    }

    struct Game {
        uint256 id;
        uint256 startTime;
        uint256 membersFilled;
        Status status;
        address[] gameMembers;
        uint256[] gameTickets;
        address[] gameWinners;
        uint256[] gameWinningAmounts;
    }

    event TicketBought(address buyer, uint256 gameId, uint256 ticketId);
    event WinnerAnnounced(address[] winners, uint256 gameId, uint256[] rewards);

    uint256 public immutable poolCapacity = 100;
    uint256 public immutable ticketPrice;
    uint256 public immutable jackpot;
    uint256 public gameCount = 0;
    uint256 ticketCount = 0;
    Game[] public games;
    
    IERC20 public immutable stableCoin;
    Vault public vault;
    mapping(address => uint256) public totalWinnningsOfUser;
    mapping(uint256 => uint256) public requestIdToGameId;
    mapping(uint256 => Ticket) public tickets;

    VRFCoordinatorV2Interface immutable COORDINATOR;
    bytes32 immutable keyHash;
    bytes32 public hashedMessage = 0x98c182dcef4c6b953bbd06b92baf2f3e237ce3a883546fdd933dadd12051d56b;
    uint64 immutable s_subscriptionId;
    uint32 immutable callbackGasLimit = 2500000;
    uint16 immutable requestConfirmations = 3;
    uint32 immutable numWords = 3;
    uint8[] gameSpots;

    uint256[6] maxNumbers = [49, 49, 49, 49, 49, 4];
    uint256 public startTime = 0; // start time of the upcomming game

    constructor(address _stableCoin, uint256 _ticketPrice, uint64 subscriptionId, address vrfContractAddress, bytes32 _keyHash, address _vaultAddress) VRFConsumerBaseV2(vrfContractAddress) {    
        ticketPrice = _ticketPrice;
        vault = Vault(payable(_vaultAddress));
        keyHash = _keyHash;
        jackpot = ticketPrice * poolCapacity;
        games.push(Game(0, block.timestamp, 0, Status.Open, new address[](poolCapacity), new uint256[](poolCapacity), new address[](3), new uint256[](3)));
        gameCount++;
        stableCoin = IERC20(_stableCoin);
        COORDINATOR = VRFCoordinatorV2Interface(
            vrfContractAddress
        );
        s_subscriptionId = subscriptionId;
        for(uint8 i=0;i<poolCapacity;i++){
            gameSpots.push(i);
        }
    }

    function buyTickets(string calldata _referrerUsername, string calldata _username, uint8 _v, bytes32 _r, bytes32 _s) external returns(Ticket memory) {
        require(block.timestamp >= startTime, "Game not started yet");
        bool hasSignedConsent = Vault(vault).hasSignedConsent(msg.sender);
        if(!hasSignedConsent){
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, hashedMessage));
            address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
            require(signer == msg.sender, "Invalid Messsage");
            Vault(vault).verifyUser(msg.sender);
        }
        Game storage game = games[games.length - 1];
        require(game.status == Status.Open, "Game is closed");
        uint256 numOfTicketsOfBuyer = 0;
        for(uint i=0; i<game.gameMembers.length; i++){
            if(game.gameMembers[i] == msg.sender){
                numOfTicketsOfBuyer++;
                if(numOfTicketsOfBuyer == 5){
                    break;
                }
            }
        }
        require(numOfTicketsOfBuyer < 5, "You can only buy 5 tickets per game");
        if(keccak256(abi.encodePacked(_referrerUsername)) != keccak256(abi.encodePacked("NA"))){
            Vault(vault).addMemberToPool(msg.sender, _referrerUsername);    
        }

        SafeERC20.safeTransferFrom(stableCoin, msg.sender, address(vault), ticketPrice);
        if(!Vault(vault).hasUsername(msg.sender)){
            Vault(vault).setUsername(msg.sender, _username);
        }
        
        // get a random number between 0 and 99 inclusive
        uint8 randomNumber = uint8(uint256(keccak256(abi.encode(block.timestamp, msg.sender))) % (poolCapacity - game.membersFilled));

        uint8 _userIndex = gameSpots[randomNumber];
        gameSpots[randomNumber] = gameSpots[poolCapacity - game.membersFilled - 1];
        gameSpots[poolCapacity - game.membersFilled - 1] = _userIndex;
        game.gameMembers[_userIndex] = msg.sender;        
        (uint8 num1, uint8 num2, uint8 num3, uint8 num4, uint8 num5, uint8 num6) = getTicket(uint256((((_userIndex + 1) * (_userIndex + 1)))));
        ticketCount++;
        tickets[ticketCount] = Ticket(num1, num2, num3, num4, num5, num6);
        game.gameTickets[_userIndex] = ticketCount;
        game.membersFilled++;
        if(game.membersFilled == poolCapacity){
            uint256 requestId = COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
            requestIdToGameId[requestId] = game.id;
            game.status = Status.Closed;
            games.push(Game(gameCount, block.timestamp, 0, Status.Open, new address[](poolCapacity), new uint256[](poolCapacity), new address[](3), new uint256[](3)));
            gameCount++;
            startTime = block.timestamp + 119;
        }
        emit TicketBought(msg.sender, game.id, ticketCount);
        return tickets[ticketCount];
    }

    function batchBuyTickets(uint256 _numberOfTickets, string calldata _referrerUsername, string calldata _username, uint8 _v, bytes32 _r, bytes32 _s) external returns(Ticket[] memory) {
        require(block.timestamp >= startTime, "Game not started yet");
        bool hasSignedConsent = Vault(vault).hasSignedConsent(msg.sender);
        if(!hasSignedConsent){
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, hashedMessage));
            address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
            require(signer == msg.sender, "Invalid Messsage");
            Vault(vault).verifyUser(msg.sender);
        }
        Game storage game = games[games.length - 1];
        require(game.status == Status.Open, "Game is closed");
        require(game.membersFilled + _numberOfTickets <= (poolCapacity*90)/100, "Batch buy is allowed till 90% of pool capacity");
        require(_numberOfTickets <= 5, "You cannot buy more than 5 tickets");
        uint256 numOfTicketsOfBuyer = 0;
        for(uint i=0; i<game.gameMembers.length; i++){
            if(game.gameMembers[i] == msg.sender){
                numOfTicketsOfBuyer++;
                if(numOfTicketsOfBuyer + _numberOfTickets > 5){
                    revert("You can hold maximum 5 tickets in a game");
                }
            }
        }
        if(keccak256(abi.encodePacked(_referrerUsername)) != keccak256(abi.encodePacked("NA"))){
            Vault(vault).addMemberToPool(msg.sender, _referrerUsername);    
        }
        SafeERC20.safeTransferFrom(stableCoin, msg.sender, address(vault), ticketPrice*_numberOfTickets);
        if(!Vault(vault).hasUsername(msg.sender)){
            Vault(vault).setUsername(msg.sender, _username);
        }
        Ticket[] memory userTickets = new Ticket[](_numberOfTickets);
        for(uint256 i=0; i<_numberOfTickets; i++){
            uint8 randomNumber = uint8(uint256(keccak256(abi.encode(block.timestamp, msg.sender, i))) % (poolCapacity - game.membersFilled));
            uint8 _userIndex = gameSpots[randomNumber];
            gameSpots[randomNumber] = gameSpots[poolCapacity - game.membersFilled - 1];
            gameSpots[poolCapacity - game.membersFilled - 1] = _userIndex;
            game.gameMembers[_userIndex] = msg.sender; 
            (uint8 num1, uint8 num2, uint8 num3, uint8 num4, uint8 num5, uint8 num6) = getTicket(uint256((((_userIndex + 1) * (_userIndex + 1)))));
            ticketCount++;
            tickets[ticketCount] = Ticket(num1, num2, num3, num4, num5, num6);
            game.gameTickets[_userIndex] = ticketCount;
            userTickets[i] = tickets[ticketCount];
            game.membersFilled++;
        }

        return userTickets;
    }

    function getTicket(uint256 index)
        internal
        view
        returns (uint8, uint8, uint8, uint8, uint8, uint8)
    {
        index += uint256(keccak256(abi.encode(block.timestamp, blockhash(block.number - 1), index))) % (1000000000);
        uint8[6] memory ticket;
        uint i = 5;
        while(i>=0){
            ticket[i] = uint8(index % (maxNumbers[i] + 1));
            if(i==5){
                ticket[i]++;
            }
            index = index / (maxNumbers[i] + 1);
            if(i == 0) break;
            i -= 1;
        }
        return (ticket[0], ticket[1], ticket[2], ticket[3], ticket[4], ticket[5]);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 gameId = requestIdToGameId[_requestId];
        Game storage game = games[gameId];
        game.status = Status.Closed;
        (uint256 winner1, uint256 winner2, uint256 winner3) = (_randomWords[0] % poolCapacity, _randomWords[1] % poolCapacity, _randomWords[2] % poolCapacity);
        if(winner1 == winner2){
            winner2 = (winner2 + 1) % poolCapacity;
        }
        if(winner1 == winner3){
            winner3 = (winner3 + 1) % poolCapacity;
        }
        if(winner2 == winner3){
            winner3 = (winner3 + 1) % poolCapacity;
        }
        if(winner1 == winner3){
            winner3 = (winner3 + 1) % poolCapacity;
        }
        
        uint256[] memory winningAmounts = new uint256[](3);
        winningAmounts[0] = ((jackpot * 90 * 40) / 10000);
        winningAmounts[1] = ((jackpot * 90 * 30) / 10000);
        winningAmounts[2] = ((jackpot * 90 * 20) / 10000);
        totalWinnningsOfUser[game.gameMembers[winner1]] += winningAmounts[0];
        totalWinnningsOfUser[game.gameMembers[winner2]] += winningAmounts[1];
        totalWinnningsOfUser[game.gameMembers[winner3]] += winningAmounts[2];
        game.gameWinners[0] = game.gameMembers[winner1];
        game.gameWinners[1] = game.gameMembers[winner2];
        game.gameWinners[2] = game.gameMembers[winner3];
        vault.distributePoolPrize(game.gameWinners, winningAmounts);
        game.gameWinningAmounts[0] = winningAmounts[0];
        game.gameWinningAmounts[1] = winningAmounts[1];
        game.gameWinningAmounts[2] = winningAmounts[2];

        emit WinnerAnnounced(game.gameWinners, gameId, winningAmounts);
    }

    function getMyTicketIds(address _user, uint256 _gameId) public view returns(uint256[] memory) {
        uint256 myTickets = 0;
        for(uint256 i = 0; i < games[_gameId].gameTickets.length; i++) {
            if(games[_gameId].gameMembers[i] == _user) {
                myTickets++;
            }
        }

        uint256[] memory myTicketIds = new uint256[](myTickets);
        uint256 count = 0;
        for(uint256 i = 0; i < games[_gameId].gameMembers.length; i++) {
            if(games[_gameId].gameMembers[i] == _user) {
                myTicketIds[count] = i;
                count++;
            }
        }
        return myTicketIds;
    }

    function getMembers(uint256 _gameId, uint256 _index) public view returns(address results){
        results = games[_gameId].gameMembers[_index];
    }

    function getTickets(uint256 _gameId, uint256 _index) public view returns(uint256 results){
        results = games[_gameId].gameTickets[_index];
    }

    function gameWinners(uint256 _gameId, uint256 _index) public view returns(address results){
        results = games[_gameId].gameWinners[_index];
    }
    
    function gameWinningAmounts(uint256 _gameId, uint256 _index) public view returns(uint256 results){
        results = games[_gameId].gameWinningAmounts[_index];
    }

    function testEvent() public {
        address[] memory arr = new address[](3);
        arr[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        arr[1] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        arr[2] = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100000000;
        amounts[1] = 200000000;
        amounts[2] = 300000000;
        emit WinnerAnnounced(arr, 1, amounts);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./LottoGame.sol";

contract Vault is VRFConsumerBaseV2 {
    IERC20 public immutable stableCoin;
    address public immutable owner;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public feeAmounts;
    mapping(address => uint256) public feePercents;
    mapping(address => uint256) public totalWinningsOfUser;
    // mapping(address => uint256) public referralCode;
    // mapping(uint256 => address) private referralCodeToAddress;
    mapping(address => string) public username;
    mapping(string => address) public usernameToAddress;
    mapping(address => bool) public hasUsername;
    mapping(address => address) public referrer;
    mapping(address => uint256) public referralRewards;
    mapping(address => uint256) public referralPoolRewards;
    mapping(address => uint256) public totalReferred;
    mapping(address => uint256) public overallReferralRewardsOfUser;
    mapping(address => bool) public hasSignedConsent;
    
    bytes32 public hashedMessage = 0x98c182dcef4c6b953bbd06b92baf2f3e237ce3a883546fdd933dadd12051d56b;

    uint256 public referralJackpot = 60000000000;
    uint256 public totalReferralWinners = 60;
    uint256 public specialWalletAmount = 0;
    address[] public feeRecepients;
    uint256 public withdrawFeePercent = 100000;
    address public immutable withdrawFeeWallet;

    address[][] public poolMembers;
    uint256 public totalBatches = 0;
    address[] public currentActiveBatch;
    mapping(uint256 => address[]) public gameToWinningBatch;
    uint256 public gameCount = 0;
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint64 immutable s_subscriptionId;
    bytes32 immutable keyHash;
    mapping(uint256 => uint256) public requestIdToGameId;
    uint32 immutable callbackGasLimit = 2500000;
    uint16 immutable requestConfirmations = 3;
    uint32 immutable numWords = 1;

    event ReferralWinnerAnnounced(address[] winners, uint256 gameId);

    constructor(
        IERC20 _stableCoin,
        address[] memory _feeRecepients,
        uint256[] memory _feePercent,
        uint64 subscriptionId,
        address vrfContractAddress,
        bytes32 _keyHash,
        address _withdrawFeeWallet
    ) VRFConsumerBaseV2(vrfContractAddress) {
        require(
            _feeRecepients.length == _feePercent.length,
            "Fee recepients and fee percent size mismatch"
        );
        feeRecepients = _feeRecepients;
        uint256 totalFeePercent = 0;
        for (uint256 i = 0; i < _feePercent.length; i++) {
            feePercents[_feeRecepients[i]] = _feePercent[i];
            totalFeePercent += _feePercent[i];
        }
        require(totalFeePercent == 100000000, "Total fee percent must be 100");
        stableCoin = _stableCoin;
        withdrawFeeWallet = _withdrawFeeWallet;
        owner = msg.sender;
        keyHash = _keyHash;
        gameCount++;
        COORDINATOR = VRFCoordinatorV2Interface(vrfContractAddress);
        s_subscriptionId = subscriptionId;
        currentActiveBatch = new address[](0);
    }

    function addWhiteListed(address[] calldata _address) external {
        require(msg.sender == owner, "Only owner can add whitelisted");
        for (uint256 i = 0; i < _address.length; i++) {
            isWhitelisted[_address[i]] = true;
        }
    }

    function removeWhiteListed(address[] calldata _address) external {
        require(msg.sender == owner, "Only owner can add whitelisted");
        for (uint256 i = 0; i < _address.length; i++) {
            isWhitelisted[_address[i]] = false;
        }
    }

    function distributePoolPrize(
        address[] calldata _address,
        uint256[] calldata _amount
    ) public {
        require(isWhitelisted[msg.sender], "Only whitelisted can add rewards");
        require(
            _address.length == _amount.length,
            "Arrays must be the same length"
        );
        uint256 jackpot = LottoGame(msg.sender).jackpot();
        uint256 fees = (jackpot * 10);
        fees = fees / 100;
        for (uint256 i = 0; i < feeRecepients.length; i++) {
            feeAmounts[feeRecepients[i]] +=
                (fees * feePercents[feeRecepients[i]]) /
                (100 * (10**6));
        }
        uint256 _referralPrice = ((jackpot - fees) * 10) / 100;
        for (uint256 i = 0; i < _address.length; i++) {
            rewards[_address[i]] += _amount[i];
            totalWinningsOfUser[_address[i]] += _amount[i];
            if (referrer[_address[i]] != address(0)) {
                referralRewards[referrer[_address[i]]] +=
                    (_referralPrice * (40 - i * 10)) /
                    100;
                overallReferralRewardsOfUser[referrer[_address[i]]] +=
                    (_referralPrice * (40 - i * 10)) /
                    100;
            } else {
                specialWalletAmount += (_referralPrice * (40 - i * 10)) / 100;
            }
        }
        specialWalletAmount += (_referralPrice * 10) / 100;
    }

    function addMemberToPool(address _address, string calldata _referralCode) public {
        require(isWhitelisted[msg.sender], "Unsupported Contract");
        require(referrer[_address] == address(0), "Referrer already set");
        require(
            usernameToAddress[_referralCode] != address(0),
            "Invalid referral code"
        );
        require(
            !hasUsername[_address],
            "User's referral code already set"
        );
        referrer[_address] = usernameToAddress[_referralCode];
        totalReferred[usernameToAddress[_referralCode]] += 1;

        currentActiveBatch.push(_address);
        if (currentActiveBatch.length == totalReferralWinners) {
            totalBatches++;
            poolMembers.push(currentActiveBatch);
            currentActiveBatch = new address[](0);
        }
        if (totalBatches >= 1 && specialWalletAmount >= referralJackpot) {
            uint256 requestId = COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
            requestIdToGameId[requestId] = gameCount;
            gameCount++;
        }
    }

    function setUsername(address _address, string calldata _username) public {
        require(isWhitelisted[msg.sender], "Only for whitelisted contracts");
        require(!hasUsername[_address], "Username already set");
        username[_address] = _username;
        usernameToAddress[_username] = _address;
        hasUsername[_address] = true;
    }

    function verifyUser(address _user) public {
        require(isWhitelisted[msg.sender], "Unsupported Contract");
        hasSignedConsent[_user] = true;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 gameId = requestIdToGameId[_requestId];
        uint256 randomNumber = _randomWords[0] % totalBatches;
        for(uint256 i=0; i< poolMembers[randomNumber].length;i++){
            referralPoolRewards[poolMembers[randomNumber][i]] += referralJackpot / totalReferralWinners;
            poolMembers[randomNumber][i] = poolMembers[poolMembers.length - 1][i];
        }
        emit ReferralWinnerAnnounced(poolMembers[poolMembers.length - 1], gameId);
        poolMembers.pop();
        totalBatches--;
    }

    function withdrawRewards() external {
        uint256 amount = rewards[msg.sender];
        uint256 fees = (amount * withdrawFeePercent) / (100 * 10**6);
        feeAmounts[withdrawFeeWallet] += fees;
        amount -= fees;
        rewards[msg.sender] = 0;
        SafeERC20.safeTransfer(stableCoin, msg.sender, amount);
    }

    function withdrawReferralRewards() external {
        uint256 amount = referralRewards[msg.sender];
        uint256 fees = (amount * withdrawFeePercent) / (100 * 10**6);
        feeAmounts[withdrawFeeWallet] += fees;
        amount -= fees;
        referralRewards[msg.sender] = 0;
        SafeERC20.safeTransfer(stableCoin, msg.sender, amount);
    }

    function withdrawReferralPoolRewards() external {
        uint256 amount = referralPoolRewards[msg.sender];
        uint256 fees = (amount * withdrawFeePercent) / (100 * 10**6);
        feeAmounts[withdrawFeeWallet] += fees;
        amount -= fees;
        referralPoolRewards[msg.sender] = 0;
        SafeERC20.safeTransfer(stableCoin, msg.sender, amount);
    }

    function withdrawFees() external {
        uint256 amount = feeAmounts[msg.sender];
        feeAmounts[msg.sender] = 0;
        SafeERC20.safeTransfer(stableCoin, msg.sender, amount);
    }

    function testEvent() public {
        address[] memory _address = new address[](totalReferralWinners);
        for (uint256 i = 0; i < totalReferralWinners; i++) {
            _address[i] = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, i)))));
        }
        emit ReferralWinnerAnnounced(_address, 0);
    }
}