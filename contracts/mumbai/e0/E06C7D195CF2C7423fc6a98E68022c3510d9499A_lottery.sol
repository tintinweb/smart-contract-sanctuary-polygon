/**
 *Submitted for verification at polygonscan.com on 2022-12-30
*/

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

pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

pragma solidity ^0.8.0;
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

pragma solidity ^0.8.0;
/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

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

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}



pragma solidity ^0.8.0;

contract lottery is ReentrancyGuard,VRFConsumerBaseV2,ConfirmedOwner {
    
    using SafeMath for uint256;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    uint32 callbackGasLimit = 400000;

    uint16 requestConfirmations = 3;

    uint32 numWords = 2;

    struct Round {
        uint256 starttime;
        uint256 endtime;
        bool activestatus;
        uint256 winningnumber4D;
        uint256 winningnumber6D;
        uint256 Bidscount4D;
        uint256 Bidscount6D;
        uint256 totalbidamount4D;
        uint256 totalbidamount6D;
        mapping(uint256 => uint256) winnerscount4D;
        mapping(uint256 => uint256) winnerscount6D;
        mapping(uint256 => uint256) winnersamount4D;
        mapping(uint256 => uint256) winnersamount6D;
    }

    mapping(uint256 => Round) public Rounds;

    uint256 public Roundscount=0;  

    address[5] public Validators;

    uint256[] public noncesUsed;
    uint256 public noncescount;  
    
    //users bid number
    mapping(uint256 => mapping(address => uint256)) public usersBid4D;
    mapping(uint256 => mapping(address => uint256)) public usersBid6D;
    
    //user position for a particular turn
    mapping(uint256 => mapping(address => uint256)) public userpositionforturn4D;
    mapping(uint256 => mapping(address => uint256)) public userpositionforturn6D;

    //claim status for a particular turn for a user
    mapping(uint256 => mapping(address => bool)) public Claimstatusforturn4D;
    mapping(uint256 => mapping(address => bool)) public Claimstatusforturn6D;

    IERC20 public usdc;

    bool public pickedstatus = false;
 
    constructor(
        uint64 subscriptionId,address _usdc

    )
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
        ConfirmedOwner(msg.sender)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        s_subscriptionId = subscriptionId;
        usdc = IERC20(_usdc);
    }

    modifier notContract() {
        require(_isContract(msg.sender) == false, "Call from Contract not allowed");
        require(msg.sender == tx.origin, "Proxy Contract not allowed");
        _;
    }

    function addvalidators(address validator1,address validator2,address validator3,address validator4,address validator5) public onlyOwner{
       Validators[0] = validator1;
       Validators[1] = validator2;
       Validators[2] = validator3;
       Validators[3] = validator4;
       Validators[4] = validator5;
    }

    function startturn() external onlyOwner notContract nonReentrant{
        require(Rounds[Roundscount].activestatus == false,"Previous Round is not finished");
        Roundscount++;
        Rounds[Roundscount].activestatus = true;
        Rounds[Roundscount].starttime = block.timestamp;
        Rounds[Roundscount].endtime = block.timestamp + 5 minutes;        
    }

    
    function guessecretno4D(uint256 n,uint256 se4) public pure returns(uint256){
        if(n == se4){
            return 0;
        }
        else if((n.mod(1000)) == (se4.mod(1000))) {
            return 1;
        }
        else if((n.mod(100)) == (se4.mod(100))) {
            return 2;
        }
        else {
            return 3;
        }
    }

    function guessecretno6D(uint256 n,uint256 se6) public pure returns(uint256){
        uint t = n.div(10000);
        uint s = se6.div(10000);
        uint p = n.div(1000);
        uint q = se6.div(1000);
        if(n == se6){
            return 0;
        }
        else if(((n.mod(100)) == (se6.mod(100))) && (t == s)) {
            return 1;
        }
        else if( (((n.div(10)).mod(100)) == ((se6.div(10)).mod(100))) && ((p.mod(100)) == (q.mod(100))) ) {
            return 2;
        }
        else {
            return 3;
        }
    }

    function countno(uint256 n) internal pure returns(uint256) {
        uint256 count=0;
    do {
    n = n / 10;
    ++count;
    } while (n != 0);
   return count;

    }

    function approveUSDC(uint256 amount) public {
        usdc.approve(address(this), amount);
    }

    function pick4Dnumber(uint256 no) public {
        require(Rounds[Roundscount].activestatus == true,"Turn has already completed");
        require(Rounds[Roundscount].endtime > block.timestamp,"Timer has expired");
        require(no > 999,"Enter four digit number");
        require(pickedstatus == false, "Random number picked");
        require(usersBid4D[Roundscount][msg.sender] == 0,"Already placed bid");
        
        usdc.transferFrom(msg.sender,address(this),5 * (10**18));
        usersBid4D[Roundscount][msg.sender] = no;
        Rounds[Roundscount].Bidscount4D++;
        Rounds[Roundscount].totalbidamount4D = Rounds[Roundscount].totalbidamount4D.add(5 * (10**18));
    }

    function pick6Dnumber(uint256 no) public {
        require(Rounds[Roundscount].activestatus == true,"Turn has already completed");
        require(Rounds[Roundscount].endtime > block.timestamp,"Timer has expired");
        require(no > 99999,"Enter six digit number");
        require(pickedstatus == false, "Random number picked");
        require(usersBid6D[Roundscount][msg.sender] == 0,"Already placed bid");
        
        usdc.transferFrom(msg.sender,address(this),5 * (10**18));
        usersBid6D[Roundscount][msg.sender] = no;
        Rounds[Roundscount].Bidscount6D++;
        Rounds[Roundscount].totalbidamount6D = Rounds[Roundscount].totalbidamount6D.add(5 * (10**18));
    }

    function pickwinningnumbers() public onlyOwner {
       require(Rounds[Roundscount].endtime <= block.timestamp, "Current timer doesnot expire");
       requestRandomWords();
       pickedstatus = true;
    }

    function endturn() public onlyOwner{
        
       require(pickedstatus == true, "Random number not picked");
       
       uint256 reqId = lastRequestId;

        Rounds[Roundscount].winningnumber4D = s_requests[reqId].randomWords[0] % 10000;
        Rounds[Roundscount].winningnumber6D = s_requests[reqId].randomWords[1] % 1000000;
        
        Rounds[Roundscount].activestatus = false;
       
        pickedstatus = false;
    }

    function checkrewards(uint256 digit) public returns(string memory,uint256){
       require(usersBid4D[Roundscount-1][msg.sender] != 0,"Only bidder can call");
       uint256 f =0;
       uint256 g =0;
       if(digit == 4){
        require(Rounds[Roundscount-1].activestatus == false,"Previous Round is not finished");
        f = guessecretno4D(Rounds[Roundscount-1].winningnumber4D, usersBid4D[Roundscount-1][msg.sender]);
          if(f == 0){
            Rounds[Roundscount-1].winnerscount4D[1]++; 
            userpositionforturn4D[Roundscount-1][msg.sender] = 1;
            return ("Guessed all 4 digits",1);
          } else if(f == 1) {
            Rounds[Roundscount-1].winnerscount4D[2]++; 
            userpositionforturn4D[Roundscount-1][msg.sender] = 2;
            return ("Guessed last 3 digits",2);
          } else if(f == 2) {
            Rounds[Roundscount-1].winnerscount4D[3]++;
            userpositionforturn4D[Roundscount-1][msg.sender] = 3;
            return ("Guessed last 2 digits",3);
          } else {
              return ("Better Luck next time",4);
          }
       } else {
        g = guessecretno6D(Rounds[Roundscount-1].winningnumber6D, usersBid6D[Roundscount-1][msg.sender]);
          if(g == 0){
            Rounds[Roundscount-1].winnerscount6D[1]++; 
            userpositionforturn6D[Roundscount-1][msg.sender] = 1;
            return ("Guessed all 6 digits",1);
          } else if(g == 1) {
            Rounds[Roundscount-1].winnerscount6D[2]++; 
            userpositionforturn6D[Roundscount-1][msg.sender] = 2;
            return ("Guessed the digits at 1,2,5,6",2);
          } else if(g == 2) {
            Rounds[Roundscount-1].winnerscount6D[3]++;
            userpositionforturn6D[Roundscount-1][msg.sender] = 3;
            return ("Guessed the digits at 2,3,4,5",3);
          } else {
              return ("Better Luck next time",4);
          }
       }
       
    }

    function calculaterewards(uint256 roundno) public onlyOwner {
    require(Rounds[roundno].endtime + 10 minutes <= block.timestamp, "Current timer doesnot expire");
    if(Rounds[roundno].totalbidamount4D >= 0) {
        if(Rounds[roundno].winnerscount4D[1] != 0){
    Rounds[roundno].winnersamount4D[1] = (Rounds[roundno].totalbidamount4D.div(2)).div(Rounds[roundno].winnerscount4D[1]);
    }
        if(Rounds[roundno].winnerscount4D[2] != 0){
    Rounds[roundno].winnersamount4D[2] = (Rounds[roundno].totalbidamount4D.div(4)).div(Rounds[roundno].winnerscount4D[2]);
    }
        if(Rounds[roundno].winnerscount4D[3] != 0){
    Rounds[roundno].winnersamount4D[3] = (Rounds[roundno].totalbidamount4D.div(5)).div(Rounds[roundno].winnerscount4D[3]);
    }
    }
    if(Rounds[roundno].totalbidamount6D >= 0) {
        if(Rounds[roundno].winnerscount6D[1] != 0){
    Rounds[roundno].winnersamount6D[1] = (Rounds[roundno].totalbidamount6D.div(2)).div(Rounds[roundno].winnerscount6D[1]);
        }
        if(Rounds[roundno].winnerscount6D[2] != 0){
    Rounds[roundno].winnersamount6D[2] = (Rounds[roundno].totalbidamount6D.div(4)).div(Rounds[roundno].winnerscount6D[2]);
        }
        if(Rounds[roundno].winnerscount6D[3] != 0){
    Rounds[roundno].winnersamount6D[3] = (Rounds[roundno].totalbidamount6D.div(5)).div(Rounds[roundno].winnerscount6D[3]);
        }
    }
    }

    function claimrewards(uint256 digit,uint256 roundno,address to) public notContract nonReentrant{
       uint256 amt = 0;
       require(userpositionforturn4D[roundno][msg.sender] != 0,"Invalid claim");
       require(Claimstatusforturn4D[roundno][msg.sender] == false,"Already claimed");
       Claimstatusforturn4D[roundno][msg.sender] = true;
       if(digit == 4){
        amt = Rounds[Roundscount].winnersamount4D[userpositionforturn4D[roundno][msg.sender]];  
       } 
       else {
        amt = Rounds[Roundscount].winnersamount6D[userpositionforturn6D[roundno][msg.sender]];
       }
        usdc.transfer(to,amt);
    }

    function getCurrentPotPrice4D() public view returns(uint256){
       return Rounds[Roundscount].totalbidamount4D;
    } 

    function getCurrentPotPrice6D() public view returns(uint256){
       return Rounds[Roundscount].totalbidamount6D;
    }  

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function withdrawtokens(address payable _paymentReceiver,uint256 _amt,uint256 nonce,bytes memory signature1,bytes memory signature2,bytes memory signature3) external {
        bool isValidator = false;
        uint256 count1 = 0;
        bool nonceValidity = true;
        
        for(uint k=0;k<noncescount;k++){
            if(noncesUsed[k] == nonce){
            nonceValidity = false;
            break;
            } 
        }

        require(nonceValidity == true, "Nonce is already used");        

        for(uint i=0;i<5;i++){
            if(msg.sender == Validators[i]){
                isValidator = true;
                break;
            }
        }

        require(isValidator == true, "Not a Validator");
         
               for(uint j=0;j<5;j++){
                   if(verifySignature(nonce,Validators[j],signature1)){
                       count1++;
                   }
               }
               for(uint j=0;j<5;j++){
                   if(verifySignature(nonce,Validators[j],signature2)){
                       count1++;
                   }
               }
            for(uint j=0;j<5;j++){
                   if(verifySignature(nonce,Validators[j],signature3)){
                       count1++;
                   }
               }
         
         require(count1 == 3, "Not enough Validators / Invalid Signatures");

         usdc.transferFrom(address(this),_paymentReceiver,_amt);
         noncesUsed.push(nonce);
         noncescount++;
    }
    
    function getMessageHash(
    uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function verifySignature(
        uint256 nonce,
        address _signer,
        bytes memory signature
    ) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
           
            r := mload(add(sig, 32))
            
            s := mload(add(sig, 64))
           
            v := byte(0, mload(add(sig, 96)))
        }

       
    }
        
    function requestRandomWords()
        public 
        onlyOwner
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);
        }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }


}