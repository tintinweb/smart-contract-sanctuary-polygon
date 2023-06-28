// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/// Local imports
import "./random/VRFv2Consumer.sol";

/**
 * @title NFTLootbox
 * @notice A smart contract for creating and managing lootboxes containing NFTs and USD prizes.
 * Players can participate in the lootbox game by paying a fee and have a chance to win NFTs or USD prizes.
 * The contract uses Chainlink VRF (Verifiable Random Function) to generate random numbers for determining the winners.
 */
contract NFTLootboxV2 is Ownable, ERC721Holder {
    error PrizeMissing();
    error InvalidProbabilitiesSum(uint256 expectedMaxValue, uint256 actual);
    error InvalidProbabilitiesCount(uint256 expected, uint256 actual);
    error InvalidLootboxDuration(uint256 maxValue, uint256 actual);
    error OutOfRangeBet(uint256 minValue, uint256 maxValue);
    error ClosedLootbox(uint256 lootboxId);
    error LootboxNotClosed(uint256 lootboxId);
    error InsufficientLootboxBalance();
    error InvalidLootbox();
    error NotFulfilled();
    error PrizeNotWon();
    error WinNotClaimed();

    struct Lootbox {
        uint256 finishTs;
        uint256 priceForPlay;
        NFT[] nftTokens;
        uint256[] usdPrizes;
        uint256[] probabilities;
        string name;
    }

    struct NFT {
        address contractAddress;
        uint256 tokenId;
    }

    struct BetDetail {
        uint256 betNum;
        uint256 lootboxId;
        uint256 randomNumRequestId;
    }

    using SafeERC20 for IERC20;

    uint256 constant MAX_PROBABILITY = 100000;
    uint256 constant LOOTBOX_MAX_DURATION = 864000; // 10 days
    uint256 constant FULFILL_PHASE = 600; // 10 minutes
    IERC20 public betCoin;
    VRFv2Consumer public vrfV2Consumer;
    uint256 public lastLootboxId;

    address[] public activePlayers;
    mapping(address => uint256) public lockedPrizes;
    mapping(uint256 => Lootbox) public lootboxes;
    mapping(address => BetDetail) public betDetails;

    event LootboxCreated(
        uint256 _priceForPlay,
        uint256 indexed _lootboxId,
        uint256 _finishTS,
        string _name,
        NFT[] nfts,
        uint256[] prizes,
        uint256[] probabilities
    );
    event Play(
        address indexed _player,
        uint256 _timestamp,
        uint256 _priceForPlay,
        uint256 indexed _lootboxId
    );
    event TakenNft(
        address indexed _user,
        address contractAddress,
        uint256 _tokenId,
        uint256 indexed _lootboxId,
        uint256 _timeStamp
    );
    event TakenUsd(
        address indexed _user,
        uint256 _amount,
        uint256 _timeStamp,
        uint256 indexed _lootboxId
    );
    event BetCoinChanged(IERC20 _betCoin);

    /**
     * @dev Constructor function
     * @param _betCoin The address of the ERC20 token used for betting
     * @param _vrfV2Consumer The address of the new VRFv2Consumer contract
     */
    constructor(IERC20 _betCoin, VRFv2Consumer _vrfV2Consumer) {
        betCoin = _betCoin;
        vrfV2Consumer = _vrfV2Consumer;
    }

    function getActivePleers() public view returns (address[] memory) {
        // for test
        return activePlayers;
    }

    /**
     * @dev Changes the address of the ERC20 token used for betting.
     * @param _betCoin The address of the new ERC20 token.
     * Emits a `BetCoinChanged` event indicating the change in ERC20 token address.
     */
    function changeBetCoin(IERC20 _betCoin) external onlyOwner {
        for (uint256 i = 1; i <= lastLootboxId; ++i) {
            if (lootboxes[i].finishTs > block.timestamp) {
                revert LootboxNotClosed(i);
            }
        }
        betCoin = _betCoin;
        emit BetCoinChanged(_betCoin);
    }

    /**
     * @dev Creates a new lootbox with the specified parameters
     * @param _priceForPlay The price in betCoin to play the lootbox
     * @param _duration The duration of the lootbox in seconds
     * @param _name The name of the lootbox
     * @param nfts An array of NFTs to be included in the lootbox
     * @param prizes An array of USD prizes to be included in the lootbox
     * @param _probabilities An array of probabilities corresponding to the NFTs and USD prizes.
     * Each number in the array represents the probability of winning the corresponding prize and is
     * expressed as a value between 1 and 100000.
     * The range of 1-100000 corresponds to a probability range of 0.001% to 100%, where a higher number
     * indicates a higher probability of winning the associated prize.
     */
    function createLootbox(
        uint256 _priceForPlay,
        uint256 _duration,
        string calldata _name,
        NFT[] calldata nfts,
        uint256[] calldata prizes,
        uint256[] calldata _probabilities
    ) external onlyOwner {
        if (nfts.length + prizes.length == 0) {
            revert PrizeMissing();
        }
        if (nfts.length + prizes.length != _probabilities.length) {
            revert InvalidProbabilitiesCount(
                nfts.length + prizes.length,
                _probabilities.length
            );
        }
        uint256 maxProbability;
        for (uint256 i; i < _probabilities.length; ++i) {
            maxProbability += _probabilities[i];
        }
        if (maxProbability > MAX_PROBABILITY) {
            revert InvalidProbabilitiesSum(MAX_PROBABILITY, maxProbability);
        }
        if (_duration > LOOTBOX_MAX_DURATION) {
            revert InvalidLootboxDuration(LOOTBOX_MAX_DURATION, _duration);
        }
        ++lastLootboxId;
        Lootbox storage loot = lootboxes[lastLootboxId];
        for (uint256 i; i < nfts.length; ++i) {
            IERC721(nfts[i].contractAddress).safeTransferFrom(
                msg.sender,
                address(this),
                nfts[i].tokenId
            );
            loot.nftTokens.push(nfts[i]);
        }
        loot.usdPrizes = prizes;
        loot.probabilities = _probabilities;
        loot.priceForPlay = _priceForPlay;
        loot.name = _name;
        loot.finishTs = block.timestamp + _duration;
        emit LootboxCreated(
            _priceForPlay,
            lastLootboxId,
            loot.finishTs,
            _name,
            nfts,
            prizes,
            _probabilities
        );
    }

    /**
     * @dev Allows a player to participate in a lootbox game
     * Players need to pay the priceForPlay in betCoin to play the lootbox.
     * If they win, they will receive a randomly selected NFT or a USD prize.
     * @param _lootboxId The ID of the lootbox to play.
     * @param _betNum The bet number, must be between 1 and 25.
     */
    function play(uint256 _lootboxId, uint256 _betNum) external {
        if (_betNum == 0 || _betNum > 25) {
            revert OutOfRangeBet(1, 25);
        }
        uint256 lootBoxMaxPrize = getLootboxMaxPrize(_lootboxId);
        Lootbox storage loot = lootboxes[_lootboxId];
        if (loot.finishTs < block.timestamp) {
            revert ClosedLootbox(_lootboxId);
        }
        if (
            lootBoxMaxPrize + updateLookedPrizes() >
            betCoin.balanceOf(address(this)) + loot.priceForPlay
        ) {
            revert InsufficientLootboxBalance();
        }
        (bool fulfilled, bool isWin, , , ) = checkWin(msg.sender);
        if (!fulfilled || isWin) {
            revert WinNotClaimed();
        }
        betCoin.safeTransferFrom(msg.sender, address(this), loot.priceForPlay);
        activePlayers.push(msg.sender);
        lockedPrizes[msg.sender] = lootBoxMaxPrize;
        BetDetail storage bet = betDetails[msg.sender];
        bet.betNum = _betNum;
        bet.lootboxId = _lootboxId;
        bet.randomNumRequestId = vrfV2Consumer.requestRandomWords();
        emit Play(msg.sender, block.timestamp, loot.priceForPlay, _lootboxId);
    }

    /**
     * @dev Claims the prize for the player
     */
    function getPrize() external {
        (
            ,
            bool isWin,
            bool isNft,
            uint256 winIndex,
            uint256 lootboxId
        ) = checkWin(msg.sender);
        if (!isWin) {
            revert PrizeNotWon();
        }
        Lootbox storage loot = lootboxes[lootboxId];
        if (isNft) {
            NFT storage _nft = loot.nftTokens[winIndex];
            IERC721 token = IERC721(_nft.contractAddress);
            token.safeTransferFrom(address(this), msg.sender, _nft.tokenId);
            loot.finishTs = block.timestamp;
            emit TakenNft(
                msg.sender,
                _nft.contractAddress,
                _nft.tokenId,
                lootboxId,
                block.timestamp
            );
        } else {
            betCoin.safeTransfer(
                msg.sender,
                loot.usdPrizes[winIndex - loot.nftTokens.length]
            );
            emit TakenUsd(
                msg.sender,
                loot.usdPrizes[winIndex - loot.nftTokens.length],
                block.timestamp,
                lootboxId
            );
        }
        delete betDetails[msg.sender];
    }

    /**
     * @dev Withdraws ERC20 tokens from the contract
     * @param _tokenAddress The address of the ERC20 token
     * @param _amount The amount of tokens to withdraw
     */
    function withdrawERC20(
        IERC20 _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        if (
            _tokenAddress == betCoin &&
            updateLookedPrizes() >=
            _tokenAddress.balanceOf(address(this)) + _amount
        ) {
            revert InsufficientLootboxBalance();
        }
        _tokenAddress.safeTransfer(msg.sender, _amount);
    }

    /**
     * @dev Withdraws ERC721 tokens from the contract
     * @param _tokenAddress The address of the ERC721 token
     * @param _tokenId The ID of the ERC721 token to withdraw
     * @param _lootboxId The ID of the lootbox associated with the token
     */
    function withdrawERC721(
        IERC721 _tokenAddress,
        uint256 _tokenId,
        uint256 _lootboxId
    ) external onlyOwner {
        if (lootboxes[_lootboxId].finishTs + FULFILL_PHASE > block.timestamp) {
            revert LootboxNotClosed(_lootboxId);
        }
        if (!checkLootboxId(address(_tokenAddress), _tokenId, _lootboxId)) {
            revert InvalidLootbox();
        }
        if (checkNftWon(address(_tokenAddress), _tokenId, _lootboxId)) {
            revert WinNotClaimed();
        }
        _tokenAddress.safeTransferFrom(address(this), msg.sender, _tokenId);
        emit TakenNft(
            msg.sender,
            address(_tokenAddress),
            _tokenId,
            _lootboxId,
            block.timestamp
        );
    }

    function checkNftWon(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _lootboxId
    ) public view returns (bool) {
        bool isNft;
        uint256 winIndex;
        uint256 lootboxId;
        for (uint256 i = 0; i < activePlayers.length; ++i) {
            (, , isNft, winIndex, lootboxId) = checkWin(activePlayers[i]);
            if (isNft && lootboxId == _lootboxId) {
                NFT storage _nft = lootboxes[lootboxId].nftTokens[winIndex];
                if (
                    _nft.contractAddress == _tokenAddress &&
                    _nft.tokenId == _tokenId
                ) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @dev Returns the NFTs, USD prizes, and probabilities of a lootbox
     * @param _lootboxId The ID of the lootbox
     * @return _nfts The array of NFTs in the lootbox
     * @return _usdPrizes The array of USD prizes in the lootbox
     * @return _probabilities The array of probabilities corresponding to the prizes
     */
    function getLootboxPrizesAndProbabilities(
        uint256 _lootboxId
    )
        external
        view
        returns (
            NFT[] memory _nfts,
            uint256[] memory _usdPrizes,
            uint256[] memory _probabilities
        )
    {
        Lootbox storage loot = lootboxes[_lootboxId];
        _nfts = loot.nftTokens;
        _usdPrizes = loot.usdPrizes;
        _probabilities = loot.probabilities;
    }

    /**
     * @dev Returns the random number generated by VRF for a given request ID
     * @param _randomNumRequestId The request ID for the random number
     * @return fulfilled True if random num fulfilled
     * @return randNum The generated random number
     */
    function getRandomNumVRF(
        uint256 _randomNumRequestId
    ) public view returns (bool fulfilled, uint256 randNum) {
        (fulfilled, randNum) = vrfV2Consumer.getRequestStatus(
            _randomNumRequestId
        );
    }

    /**
     * @dev Checks if a player has won in a bet and provides additional details
     * @param player The address of the player
     * @return fulfilled True if random num fulfilled
     * @return isWin True if the player has won, false otherwise
     * @return isNft True if the player has won an NFT prize, false otherwise
     * @return winIndex The index of the winning prize
     * @return lootboxId The ID of the lootbox associated with the bet
     */
    function checkWin(
        address player
    )
        public
        view
        returns (
            bool fulfilled,
            bool isWin,
            bool isNft,
            uint256 winIndex,
            uint256 lootboxId
        )
    {
        BetDetail storage bet = betDetails[player];
        lootboxId = bet.lootboxId;

        // If the player hasn't made a bet, return false and the lootbox ID
        if (bet.randomNumRequestId == 0) {
            return (true, false, false, 0, lootboxId);
        }
        uint256 randomNumber;
        (fulfilled, randomNumber) = getRandomNumVRF(bet.randomNumRequestId);
        if (!fulfilled) {
            return (fulfilled, false, false, 0, lootboxId);
        }
        Lootbox storage loot = lootboxes[bet.lootboxId];
        uint256 prizesCount = loot.nftTokens.length + loot.usdPrizes.length;

        // Generate a random number based on the player's bet
        randomNumber += bet.betNum;

        // Modulo operation to ensure the number is within the range of 0 to 99,999 (inclusive),
        // corresponding to the entire probability range from 0.001% to 100%.
        // This allows for a fair distribution of random numbers across the entire probability spectrum.
        randomNumber %= MAX_PROBABILITY;

        // Get the index of the prize won by the player
        winIndex = getPrizeIndex(lootboxId, randomNumber);

        // Check if the player has won a prize
        if (winIndex < prizesCount) {
            isWin = true;
            if (winIndex < loot.nftTokens.length) {
                NFT storage _nft = lootboxes[lootboxId].nftTokens[winIndex];
                IERC721 token = IERC721(_nft.contractAddress);
                if (token.ownerOf(_nft.tokenId) != address(this)) {
                    return (true, false, false, 0, lootboxId);
                }
                isNft = true;
            }
        }
    }

    /**
     * @dev Calculates the index of the prize based on the generated random number and the probabilities
     * @param _lootboxId The ID of the lootbox
     * @param _randomNumber The generated random number
     * @return The index of the prize
     */
    function getPrizeIndex(
        uint256 _lootboxId,
        uint256 _randomNumber
    ) public view returns (uint256) {
        uint256[] storage _probabilities = lootboxes[_lootboxId].probabilities;
        uint256 sum;

        // Calculate the cumulative sum of probabilities and find the winning prize
        for (uint256 i; i < _probabilities.length; ++i) {
            sum += _probabilities[i];
            if (_randomNumber <= sum) {
                return i;
            }
        }

        // If no prize is won, return a missing prize index (100001)
        return MAX_PROBABILITY + 1;
    }

    /**
     * @dev Returns the maximum prize amount among NFTs and USD prizes in a lootbox
     * @param _lootboxId The ID of the lootbox
     * @return maxPrize The maximum prize amount
     */
    function getLootboxMaxPrize(
        uint256 _lootboxId
    ) public view returns (uint256 maxPrize) {
        Lootbox storage loot = lootboxes[_lootboxId];
        for (uint256 i; i < loot.usdPrizes.length; ++i) {
            if (loot.usdPrizes[i] > maxPrize) {
                maxPrize = loot.usdPrizes[i];
            }
        }
        return maxPrize;
    }

    /**
     * @dev Checks if a given NFT is included in a specific lootbox
     * @param _tokenAddress The address of the NFT contract
     * @param _tokenId The ID of the NFT
     * @param _lootboxId The ID of the lootbox
     * @return True if the NFT is included in the lootbox, false otherwise
     */
    function checkLootboxId(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _lootboxId
    ) public view returns (bool) {
        NFT[] storage _nfts = lootboxes[_lootboxId].nftTokens;
        for (uint256 i; i < _nfts.length; ++i) {
            if (
                _nfts[i].contractAddress == _tokenAddress &&
                _nfts[i].tokenId == _tokenId
            ) {
                return true;
            }
        }
        return false;
    }

    function updateLookedPrizes() public returns (uint256) {
        bool win;
        bool fulfilled;
        uint256 winAmount;
        for (uint256 i = 0; i < activePlayers.length; ) {
            (fulfilled, win, , , ) = checkWin(activePlayers[i]);
            if (fulfilled && !win) {
                delete lockedPrizes[activePlayers[i]];
                activePlayers[i] = activePlayers[activePlayers.length - 1];
                activePlayers.pop();
            } else {
                winAmount += lockedPrizes[activePlayers[i]];
                ++i;
            }
        }
        return winAmount;
    }
}

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract VRFv2Consumer is VRFConsumerBaseV2, ConfirmedOwner {
    error RequestNotFound(uint256 requestId);
    error UnauthorizedAccess(address account);
    error AdminAlreadySet();

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256 randomWord;
    }

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this contract.
    uint32 internal constant CALLBACK_GAS_LIMIT = 100000;

    uint32 internal constant NUM_WORDS = 1;
    uint16 internal constant REQUEST_CONFIRMATIONS = 3;

    // Your subscription ID.
    uint64 internal subscriptionId;

    bytes32 internal keyHash;
    VRFCoordinatorV2Interface internal coordinator;

    // past requestStatuses Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    mapping(uint256 => RequestStatus) public requestStatuses;
    address public admin;

    event RequestSent(uint256 requestId, uint32 NUM_WORDS);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event AdminSet(address admin);
    event KeyHashChanged(bytes32 keyHash);

    /**
     * @dev Contract constructor.
     * @param _subscriptionId The subscription ID.
     * @param _keyHash The key hash for generating random numbers.
     * @param _coordinator The address of the VRF coordinator.
     */
    constructor(
        uint64 _subscriptionId,
        bytes32 _keyHash,
        address _coordinator
    ) VRFConsumerBaseV2(_coordinator) ConfirmedOwner(msg.sender) {
        coordinator = VRFCoordinatorV2Interface(_coordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }

    modifier onlyAdmin() {
        if (admin != msg.sender) {
            revert UnauthorizedAccess(msg.sender);
        }
        _;
    }

    /**
     * @dev Changes the key hash for generating random numbers.
     * @param _keyHash The new key hash.
     * Emits a `KeyHashChanged` event indicating the change in key hash.
     */
    function changeKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
        emit KeyHashChanged(_keyHash);
    }

    /**
     * @notice Sets the admin address for the contract.
     * @dev Only the contract owner can call this function.
     * @param _admin The address to set as the admin.
     * @dev If the admin address has already been set, the function reverts.
     * @dev Emits an `AdminSet` event upon successful execution.
     */
    function setAdmin(address _admin) external onlyOwner {
        if(admin != address(0)){
            revert AdminAlreadySet();
        }
        admin = _admin;
        emit AdminSet(_admin);
    }

    /**
     * @dev Requests random words from the VRF coordinator.
     * Assumes the subscription is funded sufficiently.
     * Only callable by admins.
     * @return requestId The ID of the request.
     */
    function requestRandomWords()
        external
        onlyAdmin
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        requestStatuses[requestId] = RequestStatus({
            randomWord: 0,
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, NUM_WORDS);
        return requestId;
    }

    /**
     * @dev Internal callback function to fulfill random words received from the VRF coordinator.
     * @param _requestId The ID of the request.
     * @param _randomWords The array of random words.
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        if (!requestStatuses[_requestId].exists) {
            revert RequestNotFound(_requestId);
        }
        requestStatuses[_requestId].fulfilled = true;
        requestStatuses[_requestId].randomWord = _randomWords[0];
        emit RequestFulfilled(_requestId, _randomWords);
    }

    /**
     * @dev Retrieves the status of a request.
     * @param _requestId The ID of the request.
     * @return fulfilled Whether the request has been fulfilled.
     * @return randomWord The random word associated with the request.
     */
    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256 randomWord) {
        if (!requestStatuses[_requestId].exists) {
            revert RequestNotFound(_requestId);
        }
        RequestStatus storage request = requestStatuses[_requestId];
        return (request.fulfilled, request.randomWord);
    }
}