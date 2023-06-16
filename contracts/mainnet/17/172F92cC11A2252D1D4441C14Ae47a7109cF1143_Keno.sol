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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @notice Minimal interface for Bank.
/// @author Romuald Hog.
interface IBank {
    /// @notice Payouts a winning bet, and allocate the house edge fee.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param profit Number of tokens to be sent to the gamer.
    /// @param fees Bet amount and bet profit fees amount.
    function payout(
        address user,
        address token,
        uint256 profit,
        uint256 fees
    ) external payable;

    /// @notice Accounts a loss bet.
    /// @dev In case of an ERC20, the bet amount should be transfered prior to this tx.
    /// @dev In case of the gas token, the bet amount is sent along with this tx.
    /// @param tokenAddress Address of the token.
    /// @param amount Loss bet amount.
    /// @param fees Bet amount and bet profit fees amount.
    function cashIn(
        address tokenAddress,
        uint256 amount,
        uint256 fees
    ) external payable;

    function getTokenOwner(address token) external view returns (address);

    function getBetRequirements(address token, uint256 multiplier)
        external
        view
        returns (
            bool,
            uint64,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {IBank} from "../bank/IBank.sol";

// import "hardhat/console.sol";

interface Wrapped {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);
}

interface IVRFCoordinatorV2 is VRFCoordinatorV2Interface {
    function getFeeConfig()
        external
        view
        returns (
            uint32 fulfillmentFlatFeeLinkPPMTier1,
            uint32 fulfillmentFlatFeeLinkPPMTier2,
            uint32 fulfillmentFlatFeeLinkPPMTier3,
            uint32 fulfillmentFlatFeeLinkPPMTier4,
            uint32 fulfillmentFlatFeeLinkPPMTier5,
            uint24 reqsForTier2,
            uint24 reqsForTier3,
            uint24 reqsForTier4,
            uint24 reqsForTier5
        );
}

/// @title Game base contract
/// @author Romuald Hog
/// @notice This should be parent contract of each games.
/// It defines all the games common functions and state variables.
/// @dev All rates are in basis point. Chainlink VRF v2 is used.
abstract contract Game is
    Ownable,
    Pausable,
    Multicall,
    VRFConsumerBaseV2,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    /// @notice Bet information struct.
    /// @param resolved Whether the bet has been resolved.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param id Bet ID generated by Chainlink VRF.
    /// @param amount The bet amount.
    /// @param timestamp of the bet used to refund in case Chainlink's callback fail.
    /// @param payout The payout amount.
    /// @param vrfCost The Chainlink VRF cost paid by player.
    struct Bet {
        bool resolved;
        address user;
        address token;
        uint256 id;
        uint256 amount;
        uint32 timestamp;
        uint256 payout;
        uint256 vrfCost;
    }

    /// @notice Token struct.
    /// @param houseEdge House edge rate.
    /// @param pendingCount Number of pending bets.
    /// @param VRFCallbackGasLimit How much gas is needed in the Chainlink VRF callback.
    /// @param VRFFees Chainlink's VRF collected fees amount.
    struct Token {
        uint16 houseEdge;
        uint64 pendingCount;
        uint32 VRFCallbackGasLimit;
        uint256 VRFFees;
    }

    /// @notice Chainlink VRF configuration struct.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param numRandomWords How many random words is needed to resolve a game's bet.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    /// @param chainlinkCoordinator Reference to the VRFCoordinatorV2 deployed contract.
    /// @param gasAfterCalculation Gas to be added for VRF cost refund.
    struct ChainlinkConfig {
        uint16 requestConfirmations;
        uint16 numRandomWords;
        bytes32 keyHash;
        IVRFCoordinatorV2 chainlinkCoordinator;
        uint256 gasAfterCalculation;
    }

    /// @notice Chainlink VRF configuration state.
    ChainlinkConfig private _chainlinkConfig;

    /// @notice Chainlink price feed.
    AggregatorV3Interface private immutable _LINK_ETH_feed;

    /// @notice Maps bets IDs to Bet information.
    mapping(uint256 => Bet) public bets;

    /// @notice Maps users addresses to bets IDs
    mapping(address => uint256[]) internal _userBets;

    /// @notice Maps tokens addresses to token configuration.
    mapping(address => Token) public tokens;

    /// @notice Maps user addresses to VRF overcharged cost.
    mapping(address => uint256) public userOverchargedVRFCost;

    /// @notice The bank that manage to payout a won bet and collect a loss bet.
    IBank public immutable bank;

    /// @notice Set the wrapped token in case of transfer issue
    Wrapped public immutable wrapped;

    /// @notice Emitted after the house edge is set for a token.
    /// @param token Address of the token.
    /// @param houseEdge House edge rate.
    event SetHouseEdge(address indexed token, uint16 houseEdge);

    /// @notice Emitted after the Chainlink callback gas limit is set for a token.
    /// @param token Address of the token.
    /// @param callbackGasLimit New Chainlink VRF callback gas limit.
    event SetVRFCallbackGasLimit(
        address indexed token,
        uint32 callbackGasLimit
    );

    /// @notice Emitted after the Chainlink config is set.
    /// @param chainlinkCoordinator Chainlink VRF V2 coordinator
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    /// @param gasAfterCalculation Gas to be added for VRF cost refund.
    event SetChainlinkConfig(
        IVRFCoordinatorV2 chainlinkCoordinator,
        uint16 requestConfirmations,
        bytes32 keyHash,
        uint256 gasAfterCalculation
    );

    /// @notice Emitted after the bet amount is transfered to the user.
    /// @param id The bet ID.
    /// @param user Address of the gamer.
    /// @param amount Number of tokens refunded.
    /// @param chainlinkVRFCost The Chainlink VRF cost refunded to player.
    event BetRefunded(
        uint256 id,
        address user,
        uint256 amount,
        uint256 chainlinkVRFCost
    );

    /// @notice Emitted after the token's VRF fees amount is transfered to the user.
    /// @param token Address of the token.
    /// @param amount Number of tokens refunded.
    event DistributeTokenVRFFees(address indexed token, uint256 amount);

    /// @notice Emitted after the user's overcharged VRF cost amount is transfered.
    /// @param user Address of the user.
    /// @param overchargedVRFCost Number of tokens refunded.
    event DistributeOverchargedVRFCost(
        address indexed user,
        uint256 overchargedVRFCost
    );

    /// @notice Emitted after the overcharged VRF cost amount is accounted.
    /// @param user Address of the user.
    /// @param overchargedVRFCost Number of tokens overcharged.
    event AccountOverchargedVRFCost(
        address indexed user,
        uint256 overchargedVRFCost
    );

    /// @notice No user's overcharged Chainlink fee.
    error NoOverchargedVRFCost();

    /// @notice Insufficient bet amount.
    /// @param minBetAmount Bet amount.
    error UnderMinBetAmount(uint256 minBetAmount);

    /// @notice Bet provided doesn't exist or was already resolved.
    error NotPendingBet();

    /// @notice Bet isn't resolved yet.
    error NotFulfilled();

    /// @notice House edge is capped at 4%.
    error ExcessiveHouseEdge();

    /// @notice Token is not allowed.
    error ForbiddenToken();

    /// @notice Chainlink price feed not working
    /// @param linkWei LINK/ETH price returned.
    error InvalidLinkWeiPrice(int256 linkWei);

    /// @notice The msg.value is not enough to cover Chainlink's fee.
    error WrongGasValueToCoverFee();

    /// @notice Reverting error when sender isn't allowed.
    error AccessDenied();

    /// @notice Reverting error when provided address isn't valid.
    error InvalidAddress();

    /// @notice Reverting error when token has pending bets.
    error TokenHasPendingBets();

    /// @notice Initialize contract's state variables and VRF Consumer.
    /// @param bankAddress The address of the bank.
    /// @param chainlinkCoordinatorAddress Address of the Chainlink VRF Coordinator.
    /// @param numRandomWords How many random words is needed to resolve a game's bet.
    /// @param LINK_ETH_feedAddress Address of the Chainlink LINK/ETH price feed.
    constructor(
        address bankAddress,
        address chainlinkCoordinatorAddress,
        uint16 numRandomWords,
        address LINK_ETH_feedAddress,
        address wrappedGasToken
    ) VRFConsumerBaseV2(chainlinkCoordinatorAddress) {
        if (
            LINK_ETH_feedAddress == address(0) ||
            chainlinkCoordinatorAddress == address(0) ||
            bankAddress == address(0)
        ) {
            revert InvalidAddress();
        }
        require(
            numRandomWords != 0 && numRandomWords <= 500,
            "Wrong Chainlink NumRandomWords"
        );

        bank = IBank(bankAddress);
        wrapped = Wrapped(wrappedGasToken);
        _chainlinkConfig.chainlinkCoordinator = IVRFCoordinatorV2(
            chainlinkCoordinatorAddress
        );
        _chainlinkConfig.numRandomWords = numRandomWords;
        _LINK_ETH_feed = AggregatorV3Interface(LINK_ETH_feedAddress);
    }

    /// @notice Calculates the amount's fee based on the house edge.
    /// @param token Address of the token.
    /// @param amount From which the fee amount will be calculated.
    /// @return The fee amount.
    function _getFees(
        address token,
        uint256 amount
    ) private view returns (uint256) {
        return (tokens[token].houseEdge * amount) / 10000;
    }

    /// @notice Creates a new bet and request randomness to Chainlink,
    /// transfer the ERC20 tokens to the contract or refund the bet amount overflow if the bet amount exceed the maxBetAmount.
    /// @param tokenAddress Address of the token.
    /// @param tokenAmount The number of tokens bet.
    /// @param multiplier The bet amount leverage determines the user's profit amount. 10000 = 100% = no profit.
    /// @return A new Bet struct information.
    function _newBet(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 multiplier
    ) internal whenNotPaused nonReentrant returns (Bet memory) {
        (
            bool isAllowedToken,
            uint64 VRFSubId,
            uint256 minBetAmount,
            uint256 maxBetAmount
        ) = bank.getBetRequirements(tokenAddress, multiplier);

        Token storage token = tokens[tokenAddress];

        if (!isAllowedToken || token.houseEdge == 0) {
            revert ForbiddenToken();
        }

        uint256 fee = tokenAddress == address(0)
            ? (msg.value - tokenAmount)
            : msg.value;
        {
            // Charge user for Chainlink VRF fee.
            uint256 chainlinkVRFCost = getChainlinkVRFCost(tokenAddress);
            if (fee < (chainlinkVRFCost - ((10 * chainlinkVRFCost) / 100))) {
                // 10% slippage.
                revert WrongGasValueToCoverFee();
            }
        }

        // Bet amount is capped.
        if (tokenAmount < minBetAmount) {
            revert UnderMinBetAmount(minBetAmount);
        } else if (tokenAmount > maxBetAmount) {
            if (tokenAddress == address(0)) {
                Address.sendValue(
                    payable(msg.sender),
                    tokenAmount - maxBetAmount
                );
            }
            tokenAmount = maxBetAmount;
        }

        // Create bet
        uint256 id = _chainlinkConfig.chainlinkCoordinator.requestRandomWords(
            _chainlinkConfig.keyHash,
            VRFSubId,
            _chainlinkConfig.requestConfirmations,
            token.VRFCallbackGasLimit,
            _chainlinkConfig.numRandomWords
        );

        Bet memory newBet = Bet(
            false,
            msg.sender,
            tokenAddress,
            id,
            tokenAmount,
            uint32(block.timestamp),
            0,
            fee
        );
        _userBets[msg.sender].push(id);
        bets[id] = newBet;

        token.pendingCount++;

        // If ERC20, transfer the tokens
        if (tokenAddress != address(0)) {
            IERC20(tokenAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenAmount
            );
        }

        return newBet;
    }

    /// @notice Calculates the overcharged VRF cost based on the gas consumed.
    /// @param bet The Bet struct information.
    /// @param startGas Gas amount at start.
    function _accountVRFCost(Bet storage bet, uint256 startGas) internal {
        (, int256 weiPerUnitLink, , , ) = _LINK_ETH_feed.latestRoundData();
        if (weiPerUnitLink < 0) {
            weiPerUnitLink = 0;
        }
        // Get Chainlink VRF v2 fee amount.
        (
            uint32 fulfillmentFlatFeeLinkPPMTier1,
            ,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = _chainlinkConfig.chainlinkCoordinator.getFeeConfig();
        // Calculates the VRF premium fee in ETH
        uint256 chainlinkPremium = ((1e12 *
            uint256(fulfillmentFlatFeeLinkPPMTier1) *
            uint256(weiPerUnitLink)) / 1e18);

        // Calculate the gas fee (adding the estimated gas spent after this calculation) + premium
        uint256 actualVRFCost = (tx.gasprice *
            (startGas - gasleft() + _chainlinkConfig.gasAfterCalculation)) +
            chainlinkPremium;

        // If the actual VRF cost is higher than what the player paid.
        if (actualVRFCost > bet.vrfCost) {
            actualVRFCost = bet.vrfCost;
        } else {
            // Otherwise credits it to his account.
            uint256 overchargedVRFCost = bet.vrfCost - actualVRFCost;
            userOverchargedVRFCost[bet.user] += overchargedVRFCost;
            bet.vrfCost = actualVRFCost;
            emit AccountOverchargedVRFCost(bet.user, overchargedVRFCost);
        }

        // Credits the actual VRF cost to fund the VRF subscription.
        tokens[bet.token].VRFFees += actualVRFCost;
    }

    /// @notice Resolves the bet based on the game child contract result.
    /// In case bet is won, the bet amount minus the house edge is transfered to user from the game contract, and the profit is transfered to the user from the Bank.
    /// In case bet is lost, the bet amount is transfered to the Bank from the game contract.
    /// @param bet The Bet struct information.
    /// @param payout What should be sent to the user in case of a won bet. Payout = bet amount + profit amount.
    /// @return The payout amount.
    /// @dev Should not revert as it resolves the bet with the randomness.
    function _resolveBet(
        Bet storage bet,
        uint256 payout
    ) internal returns (uint256) {
        if (bet.resolved == true || bet.id == 0) {
            revert NotPendingBet();
        }
        bet.resolved = true;

        address token = bet.token;
        tokens[token].pendingCount--;

        uint256 betAmount = bet.amount;
        bool isGasToken = bet.token == address(0);

        if (payout > betAmount) {
            // The user has won more than his bet
            address user = bet.user;

            uint256 profit = payout - betAmount;
            uint256 betAmountFee = _getFees(token, betAmount);
            uint256 profitFee = _getFees(token, profit);
            uint256 fee = betAmountFee + profitFee;

            payout -= fee;

            uint256 betAmountPayout = betAmount - betAmountFee;
            uint256 profitPayout = profit - profitFee;
            // Transfer the bet amount payout to the player
            if (isGasToken) {
                Address.sendValue(payable(user), betAmountPayout);
            } else {
                IERC20(token).safeTransfer(user, betAmountPayout);
                // Transfer the bet amount fee to the bank.
                IERC20(token).safeTransfer(address(bank), betAmountFee);
            }

            // Transfer the payout from the bank, the bet amount fee to the bank, and account fees.
            bank.payout{value: isGasToken ? betAmountFee : 0}(
                user,
                token,
                profitPayout,
                fee
            );
        } else if (payout > 0) {
            // The user has won something smaller than his bet
            address user = bet.user;

            uint256 fee = _getFees(token, payout);
            payout -= fee;
            uint256 bankCashIn = betAmount - payout;

            // Transfer the bet amount payout to the player
            if (isGasToken) {
                Address.sendValue(payable(user), payout);
            } else {
                IERC20(token).safeTransfer(user, payout);
                // Transfer the lost bet amount and fee to the bank
                IERC20(token).safeTransfer(address(bank), bankCashIn);
            }

            bank.cashIn{value: isGasToken ? bankCashIn : 0}(
                token,
                bankCashIn,
                fee
            );
        } else {
            // The user did not win anything
            if (!isGasToken) {
                IERC20(token).safeTransfer(address(bank), betAmount);
            }
            bank.cashIn{value: isGasToken ? betAmount : 0}(token, betAmount, 0);
        }

        bet.payout = payout;
        return payout;
    }

    function silentTransfer(
        address payable recipient,
        uint256 amount
    ) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");

        if (!success) {
            // Fallback to wrapped gas token in case of error
            wrapped.deposit{value: amount}();
            wrapped.transfer(recipient, amount);
        }
    }

    /// @notice Gets the list of the last user bets.
    /// @param user Address of the gamer.
    /// @param dataLength The amount of bets to return.
    /// @return A list of Bet.
    function _getLastUserBets(
        address user,
        uint256 dataLength
    ) internal view returns (Bet[] memory) {
        uint256[] memory userBetsIds = _userBets[user];
        uint256 betsLength = userBetsIds.length;

        if (betsLength < dataLength) {
            dataLength = betsLength;
        }

        Bet[] memory userBets = new Bet[](dataLength);
        if (dataLength != 0) {
            uint256 userBetsIndex;
            for (uint256 i = betsLength; i > betsLength - dataLength; i--) {
                userBets[userBetsIndex] = bets[userBetsIds[i - 1]];
                userBetsIndex++;
            }
        }

        return userBets;
    }

    /// @notice Sets the game house edge rate for a specific token.
    /// @param token Address of the token.
    /// @param houseEdge House edge rate.
    /// @dev The house edge rate couldn't exceed 4%.
    function setHouseEdge(address token, uint16 houseEdge) external onlyOwner {
        if (houseEdge > 400) {
            revert ExcessiveHouseEdge();
        }
        if (hasPendingBets(token)) {
            revert TokenHasPendingBets();
        }
        tokens[token].houseEdge = houseEdge;
        emit SetHouseEdge(token, houseEdge);
    }

    /// @notice Pauses the contract to disable new bets.
    function pause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /// @notice Sets the Chainlink VRF V2 configuration.
    /// @param chainlinkCoordinator Chainlink VRF V2 coordinator
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    /// @param gasAfterCalculation Gas to be added for VRF cost refund.
    function setChainlinkConfig(
        IVRFCoordinatorV2 chainlinkCoordinator,
        uint16 requestConfirmations,
        bytes32 keyHash,
        uint256 gasAfterCalculation
    ) external onlyOwner {
        _chainlinkConfig.chainlinkCoordinator = chainlinkCoordinator;
        _chainlinkConfig.requestConfirmations = requestConfirmations;
        _chainlinkConfig.keyHash = keyHash;
        _chainlinkConfig.gasAfterCalculation = gasAfterCalculation;
        emit SetChainlinkConfig(
            chainlinkCoordinator,
            requestConfirmations,
            keyHash,
            gasAfterCalculation
        );
    }

    /// @notice Sets the Chainlink VRF V2 configuration.
    /// @param callbackGasLimit How much gas is needed in the Chainlink VRF callback.
    function setVRFCallbackGasLimit(
        address token,
        uint32 callbackGasLimit
    ) external onlyOwner {
        tokens[token].VRFCallbackGasLimit = callbackGasLimit;
        emit SetVRFCallbackGasLimit(token, callbackGasLimit);
    }

    /// @notice Distributes the token's collected Chainlink fees.
    /// @param token Address of the token.
    function withdrawTokensVRFFees(address token) external {
        uint256 tokenChainlinkFees = tokens[token].VRFFees;
        if (tokenChainlinkFees != 0) {
            delete tokens[token].VRFFees;
            Address.sendValue(
                payable(bank.getTokenOwner(token)),
                tokenChainlinkFees
            );
            emit DistributeTokenVRFFees(token, tokenChainlinkFees);
        }
    }

    /// @notice Withdraw user's overcharged Chainlink fees.
    function withdrawOverchargedVRFCost(address user) external {
        uint256 overchargedVRFCost = userOverchargedVRFCost[user];
        if (overchargedVRFCost == 0) {
            revert NoOverchargedVRFCost();
        }

        delete userOverchargedVRFCost[user];
        Address.sendValue(payable(user), overchargedVRFCost);
        emit DistributeOverchargedVRFCost(user, overchargedVRFCost);
    }

    /// @notice Refunds the bet to the user if the Chainlink VRF callback failed.
    /// @param id The Bet ID.
    function refundBet(uint256 id) external {
        Bet storage bet = bets[id];
        if (bet.resolved == true || bet.id == 0) {
            revert NotPendingBet();
        } else if (block.timestamp < bet.timestamp + 60 * 60 * 24) {
            revert NotFulfilled();
        }

        Token storage token = tokens[bet.token];
        token.pendingCount--;

        bet.resolved = true;
        bet.payout = bet.amount;

        uint256 chainlinkVRFCost = bet.vrfCost;
        if (bet.token == address(0)) {
            silentTransfer(payable(bet.user), bet.amount + chainlinkVRFCost);
        } else {
            IERC20(bet.token).safeTransfer(bet.user, bet.amount);
            silentTransfer(payable(bet.user), chainlinkVRFCost);
        }

        emit BetRefunded(id, bet.user, bet.amount, chainlinkVRFCost);
    }

    /// @notice Returns the Chainlink VRF config.
    /// @param requestConfirmations How many confirmations the Chainlink node should wait before responding.
    /// @param keyHash Hash of the public key used to verify the VRF proof.
    /// @param chainlinkCoordinator Reference to the VRFCoordinatorV2 deployed contract.
    /// @param gasAfterCalculation Gas to be added for VRF cost refund.
    function getChainlinkConfig()
        external
        view
        returns (
            uint16 requestConfirmations,
            bytes32 keyHash,
            IVRFCoordinatorV2 chainlinkCoordinator,
            uint256 gasAfterCalculation
        )
    {
        return (
            _chainlinkConfig.requestConfirmations,
            _chainlinkConfig.keyHash,
            _chainlinkConfig.chainlinkCoordinator,
            _chainlinkConfig.gasAfterCalculation
        );
    }

    /// @notice Returns whether the token has pending bets.
    /// @return Whether the token has pending bets.
    function hasPendingBets(address token) public view returns (bool) {
        return tokens[token].pendingCount != 0;
    }

    /// @notice Returns the amount of ETH that should be passed to the wager transaction.
    /// to cover Chainlink VRF fee.
    /// @return The bet resolution cost amount.
    function getChainlinkVRFCost(address token) public view returns (uint256) {
        (, int256 weiPerUnitLink, , , ) = _LINK_ETH_feed.latestRoundData();
        if (weiPerUnitLink <= 0) {
            revert InvalidLinkWeiPrice(weiPerUnitLink);
        }
        // Get Chainlink VRF v2 fee amount.
        (
            uint32 fulfillmentFlatFeeLinkPPMTier1,
            ,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = _chainlinkConfig.chainlinkCoordinator.getFeeConfig();
        // 115000 gas is the average Verification gas of Chainlink VRF.
        return
            (tx.gasprice * (115000 + tokens[token].VRFCallbackGasLimit)) +
            ((1e12 *
                uint256(fulfillmentFlatFeeLinkPPMTier1) *
                uint256(weiPerUnitLink)) / 1e18);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Game} from "./Game.sol";

/// @title BetSwirl's Keno game
/// @notice

contract Keno is Game {
    /// @notice Full keno bet information struct.
    /// @param bet The Bet struct information.
    /// @param kenoBet The Keno bet struct information.
    /// @dev Used to package bet information for the front-end.
    struct FullKenoBet {
        Bet bet;
        KenoBet kenoBet;
    }

    /// @notice Keno bet information struct.
    /// @param bet The Bet struct information.
    /// @param numbers The chosen numbers.
    struct KenoBet {
        uint40 numbers;
        uint40 rolled;
    }

    /// @notice stores the settings for a specific token
    /// @param biggestNumber Sets the biggest number that can be played
    /// @param maxNumbersPlayed Sets the maximum numbers that can be picked
    struct TokenConfig {
        uint128 biggestNumber;
        uint128 maxNumbersPlayed;
    }

    /// @notice Maps bets IDs to chosen numbers.
    mapping(uint256 => KenoBet) public kenoBets;

    /// @notice Maps all possible factors.
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256[])))
        private gainsFactor;

    /// @notice Maps all token configs
    mapping(address => TokenConfig) public tokenConfigurations;

    uint256 private constant FACTORPRECISION = 10000;

    /// @notice Emitted after a bet is placed.
    /// @param id The bet ID.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param amount The bet amount.
    /// @param vrfCost The Chainlink VRF cost paid by player.
    /// @param numbers The chosen numbers.
    event PlaceBet(
        uint256 id,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 vrfCost,
        uint40 numbers
    );

    /// @notice Emitted after a bet is rolled.
    /// @param id The bet ID.
    /// @param user Address of the gamer.
    /// @param token Address of the token.
    /// @param amount The bet amount.
    /// @param numbers The chosen numbers.
    /// @param rolled The rolled number.
    /// @param payout The payout amount.
    event Roll(
        uint256 indexed id,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint40 numbers,
        uint40 rolled,
        uint256 payout
    );

    /// @notice Emitted when the settings are updated for a specific token
    /// @param newBiggestNumber The new biggest number
    /// @param newMaxNumbers The new maximum of pick
    event TokenConfigUpdated(
        address token,
        uint128 newBiggestNumber,
        uint128 newMaxNumbers
    );

    /// @notice Numbers provided is not in the allowed range
    error NumbersNotInRange();

    /// @notice Too many numbers are submitted.
    error TooManyNumbersPlayed();

    /// @notice Thrown when settings could block the contract.
    error InvalidSettings();

    /// @notice Initialize the game base contract.
    /// @param bankAddress The address of the bank.
    /// @param chainlinkCoordinatorAddress Address of the Chainlink VRF Coordinator.
    /// @param LINK_ETH_feedAddress Address of the Chainlink LINK/ETH price feed.
    constructor(
        address bankAddress,
        address chainlinkCoordinatorAddress,
        address LINK_ETH_feedAddress,
        address wrappedGasToken
    ) Game(bankAddress,
           chainlinkCoordinatorAddress,
           1,
           LINK_ETH_feedAddress,
           wrappedGasToken) {}

    /// @notice Calculate all gain factors
    /// @param token used
    function _calculateFactors(address token) private {
        TokenConfig memory config = tokenConfigurations[token];
        for (uint256 played = 1; played <= config.maxNumbersPlayed; played++) {
            uint256[] storage factors = gainsFactor[config.biggestNumber][
                config.maxNumbersPlayed
            ][played];
            if (factors.length == 0) {
                for (
                    uint256 matchCount = 0;
                    matchCount <= played;
                    matchCount++
                ) {
                    factors.push(gain(token, played, matchCount));
                }
            }
        }
    }

    /// @notice Updates the settings for a specific token
    /// @param newBiggestNumber The new biggest number
    /// @param newMaxNumbers The new maximum of pick
    function updateTokenConfig(
        address token,
        uint128 newBiggestNumber,
        uint128 newMaxNumbers
    ) external onlyOwner {
        if (hasPendingBets(token)) {
            revert TokenHasPendingBets();
        }
        if (
            newMaxNumbers > newBiggestNumber ||
            newBiggestNumber > 40 ||
            newMaxNumbers > 10
        ) revert InvalidSettings();

        TokenConfig storage config = tokenConfigurations[token];
        config.biggestNumber = newBiggestNumber;
        config.maxNumbersPlayed = newMaxNumbers;

        _calculateFactors(token);
        emit TokenConfigUpdated(token, newBiggestNumber, newMaxNumbers);
    }

    /// @notice Calculates the target payout amount.
    /// @param betAmount Bet amount.
    /// @param played the count of numbers played
    /// @param matchCount the count of matching numbers
    /// @return factor The target payout amount.
    function _getPayout(
        address token,
        uint256 betAmount,
        uint256 played,
        uint256 matchCount
    ) private view returns (uint256 factor) {
        TokenConfig memory config = tokenConfigurations[token];
        factor =
            (betAmount *
                gainsFactor[config.biggestNumber][config.maxNumbersPlayed][
                    played
                ][matchCount]) /
            FACTORPRECISION;
    }

    /// @notice Creates a new bet and stores the chosen bet mask.
    /// @param numbers The chosen numbers.
    /// @param token Address of the token.
    /// @param tokenAmount The number of tokens bet.
    function wager(
        uint40 numbers,
        address token,
        uint256 tokenAmount
    ) external payable whenNotPaused {
        TokenConfig memory config = tokenConfigurations[token];
        if (numbers == 0 || numbers >= 2 ** config.biggestNumber - 1) {
            revert NumbersNotInRange();
        }

        uint256 _count = _countNumbers(numbers);
        if (_count > config.maxNumbersPlayed) {
            revert TooManyNumbersPlayed();
        }

        Bet memory bet = _newBet(
            token,
            tokenAmount,
            _getPayout(token, 10000, _count, _count)
        );

        kenoBets[bet.id].numbers = numbers;

        emit PlaceBet(
            bet.id,
            bet.user,
            bet.token,
            bet.amount,
            bet.vrfCost,
            numbers
        );
    }

    /// @notice Count how many numbers are encoded
    /// @param numbers The binary encoded list of numbers
    /// @return count The total of numbers encoded
    function _countNumbers(
        uint40 numbers
    ) private pure returns (uint256 count) {
        if (numbers & 0x1 > 0) count++;
        if (numbers & 0x2 > 0) count++;
        if (numbers & 0x4 > 0) count++;
        if (numbers & 0x8 > 0) count++;

        if (numbers & 0x10 > 0) count++;
        if (numbers & 0x20 > 0) count++;
        if (numbers & 0x40 > 0) count++;
        if (numbers & 0x80 > 0) count++;

        if (numbers & 0x100 > 0) count++;
        if (numbers & 0x200 > 0) count++;
        if (numbers & 0x400 > 0) count++;
        if (numbers & 0x800 > 0) count++;

        if (numbers & 0x1000 > 0) count++;
        if (numbers & 0x2000 > 0) count++;
        if (numbers & 0x4000 > 0) count++;
        if (numbers & 0x8000 > 0) count++;

        if (numbers & 0x10000 > 0) count++;
        if (numbers & 0x20000 > 0) count++;
        if (numbers & 0x40000 > 0) count++;
        if (numbers & 0x80000 > 0) count++;

        if (numbers & 0x100000 > 0) count++;
        if (numbers & 0x200000 > 0) count++;
        if (numbers & 0x400000 > 0) count++;
        if (numbers & 0x800000 > 0) count++;

        if (numbers & 0x1000000 > 0) count++;
        if (numbers & 0x2000000 > 0) count++;
        if (numbers & 0x4000000 > 0) count++;
        if (numbers & 0x8000000 > 0) count++;

        if (numbers & 0x10000000 > 0) count++;
        if (numbers & 0x20000000 > 0) count++;
        if (numbers & 0x40000000 > 0) count++;
        if (numbers & 0x80000000 > 0) count++;

        if (numbers & 0x100000000 > 0) count++;
        if (numbers & 0x200000000 > 0) count++;
        if (numbers & 0x400000000 > 0) count++;
        if (numbers & 0x800000000 > 0) count++;

        if (numbers & 0x1000000000 > 0) count++;
        if (numbers & 0x2000000000 > 0) count++;
        if (numbers & 0x4000000000 > 0) count++;
        if (numbers & 0x8000000000 > 0) count++;
    }

    /// @notice Resolves the bet using the Chainlink randomness.
    /// @param id The bet ID.
    /// @param randomWords Random words list. Contains only one for this game.
    // solhint-disable-next-line private-vars-leading-underscore
    function fulfillRandomWords(
        uint256 id,
        uint256[] memory randomWords
    ) internal override {
        uint256 startGas = gasleft();

        KenoBet storage kenoBet = kenoBets[id];
        Bet storage bet = bets[id];
        uint40 rolled = getNumbersOutOfRandomWord(bet.token, randomWords[0]);

        kenoBet.rolled = rolled;
        uint256 _gain = _getPayout(
            bet.token,
            bet.amount,
            _countNumbers(kenoBet.numbers),
            _countNumbers(kenoBet.numbers & rolled)
        );

        uint256 payout = _resolveBet(bet, _gain);

        emit Roll(
            bet.id,
            bet.user,
            bet.token,
            bet.amount,
            kenoBet.numbers,
            rolled,
            payout
        );

        _accountVRFCost(bet, startGas);
    }

    /// @notice Calculate the _factorial of a number
    /// @param n Param for the calculation
    /// @return result The _factorial result
    function _fact(uint256 n) private pure returns (uint256 result) {
        if (n == 0) return 1;
        result = n;
        for (uint i = n - 1; i > 1; i--) {
            result = result * i;
        }
    }

    /// @notice Calculate the proability to draw x items out of n
    /// @param n Total number
    /// @param x Number of Trials
    /// @return The mathematical result
    function _outof(uint n, uint x) private pure returns (uint256) {
        return _fact(n) / (_fact(x) * _fact(n - x));
    }

    /// @notice Calculate the gain ratio based on Hypergeometric formula
    /// @param played Number of numbers chosen
    /// @param matchCount Number of winning numbers
    /// @return _factor The gain _factor
    function gain(
        address token,
        uint256 played,
        uint256 matchCount
    ) public view returns (uint256 _factor) {
        TokenConfig memory config = tokenConfigurations[token];

        uint256 hypergeometricNumerator = _outof(played, matchCount) *
            _outof(
                config.biggestNumber - played,
                config.maxNumbersPlayed - matchCount
            );
        uint256 hypergeometricDenominator = _outof(
            config.biggestNumber,
            config.maxNumbersPlayed
        );

        // Calculate the inverse of the hypergeometric function
        _factor =
            (FACTORPRECISION * hypergeometricDenominator) /
            (hypergeometricNumerator * (played + 1));
    }

    /// @notice returns all gains table for one token
    /// @param token used
    function gains(address token) external view returns(uint biggestNumber, uint maxNumbersPlayed, uint256[][] memory _gainsTable) {
        TokenConfig memory config = tokenConfigurations[token];
        _gainsTable = new uint256[][](config.maxNumbersPlayed);
        biggestNumber = config.biggestNumber;
        maxNumbersPlayed = config.maxNumbersPlayed;
        for(uint256 played = 1; played <= config.maxNumbersPlayed; played++) {
            uint256[] memory _gains = new uint256[](played + 1);
            for(uint256 matchCount = 0; matchCount <= played; matchCount++) {
                _gains[matchCount] = gainsFactor[config.biggestNumber][config.maxNumbersPlayed][played][matchCount];
            }
            _gainsTable[played-1] = _gains;
        }
    }

    /// @notice Transforms a random word into a suite of number encoded in binary
    /// @param randomWord The source of randomness
    /// @return result The encoded numbers list
    function getNumbersOutOfRandomWord(
        address token,
        uint256 randomWord
    ) public view returns (uint40) {
        uint256 result = 0;
        TokenConfig memory config = tokenConfigurations[token];
        for (uint256 i = 0; i < config.maxNumbersPlayed; i++) {
            // Draw a number
            uint256 current = ((randomWord & 0xFF) % config.biggestNumber) + 1;

            // Check if number does not already exist
            uint256 bitmask = 2 ** (current - 1);
            while ((result & bitmask) != 0) {
                // Draw the next number is it does already exist
                current += 1;

                // Loop back to the first number if biggest number is reached
                if (current > config.biggestNumber) current = 1;
                bitmask = 2 ** (current - 1);
            }

            // Add the number to the result
            result = result | bitmask;

            // Offset to draw the next one
            randomWord = randomWord >> 8;
        }
        return uint40(result);
    }

    /// @notice Gets the list of the last user bets.
    /// @param user Address of the gamer.
    /// @param dataLength The amount of bets to return.
    /// @return A list of Keno bet.
    function getLastUserBets(
        address user,
        uint256 dataLength
    ) external view returns (FullKenoBet[] memory) {
        Bet[] memory lastBets = _getLastUserBets(user, dataLength);
        FullKenoBet[] memory lastKenoBets = new FullKenoBet[](lastBets.length);
        for (uint256 i; i < lastBets.length; i++) {
            lastKenoBets[i] = FullKenoBet(
                lastBets[i],
                kenoBets[lastBets[i].id]
            );
        }
        return lastKenoBets;
    }
}