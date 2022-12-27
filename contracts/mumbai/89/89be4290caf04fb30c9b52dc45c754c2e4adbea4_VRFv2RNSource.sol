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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
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

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity ^0.8.7;

import "src/interfaces/IVRFv2RNSource.sol";
import "src/interfaces/ILottery.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract VRFv2RNSource is IVRFv2RNSource, Ownable2Step, VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface public immutable coordinator;
    bytes32 public immutable keyHash;
    uint16 public immutable requestConfirmations;
    uint64 public immutable subscriptionId;
    uint32 public immutable callbackGasLimit;

    mapping(address => bool) public registeredConsumer;
    mapping(uint256 => RequestStatus) public requests;

    constructor(
        address _coordinator,
        bytes32 _keyHash, 
        uint16 _requestConfirmations,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit
    )
        VRFConsumerBaseV2(_coordinator)
    {
        coordinator = VRFCoordinatorV2Interface(_coordinator);
        keyHash = _keyHash;
        requestConfirmations = _requestConfirmations;
        subscriptionId = _subscriptionId;
        callbackGasLimit = _callbackGasLimit;
    }

    function authoriseConsumer(address consumer, bool isAuthorised) external onlyOwner {
        registeredConsumer[consumer] = isAuthorised;
    }

    /// @dev Assumes the Chainlink VRFv2 subscription is funded sufficiently
    function requestRandomNumber() external override returns (uint256 requestId)
    {
        if (!registeredConsumer[msg.sender]) {
            revert UnauthorizedConsumer(msg.sender);
        }

        requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1
        );

        requests[requestId] = RequestStatus({
            consumer: msg.sender,
            randomNumber: 0,
            fulfilled: false
        });

        emit RequestedRandomNumber(requestId);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        if (requests[requestId].consumer == address(0)) {
            revert RequestNotFound(requestId);
        }
        if (randomWords.length != 1) {
            revert WrongRandomNumberCountReceived(requestId, randomWords.length);
        }
        requests[requestId].fulfilled = true;
        requests[requestId].randomNumber = randomWords[0];
        IRNSourceCounsumer(requests[requestId].consumer).onRandomNumberFulfilled(randomWords[0]);

        emit RequestFulfilled(requestId, randomWords[0]);
    }
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.17;

import "src/interfaces/IRNSource.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Provided reward token is zero
error RewardTokenZero();

/// @dev Provided random number source is zero
error RandomNumberSourceZero();

/// @dev Provided draw period is zero
error DrawPeriodZero();

/// @dev Provided ticket price is zero
error TicketPriceZero();

/// @dev Ticket fee is set to big
error TicketFeeTooBig();

/// @dev Provided selection size iz zero
error SelectionSizeZero();

/// @dev Provided selection size is too big
error SelectionSizeTooBig();

/// @dev Provided fee recipient is zero address
error FeeRecipientZeroAddress();

/// @dev Cannot execute draw if it is already executing
error DrawAlreadyInProgress();

/// @dev Cannot finalise draw if it is not started
error DrawNotInProgress();

/// @dev Executing draw before it's scheduled period
error ExecutingDrawTooEarly();

/// @dev Provided draw id is from past
error DrawFromPast();

/// @dev Provided arrays of drawIds and Tickets with different length
/// @param drawIdsLen Length of drawIds array
/// @param ticketsLen Length of tickets array
error DrawsAndTicketsLenMismatch(uint256 drawIdsLen, uint256 ticketsLen);

/// @dev Method called by an unauthorized caller
error Unauthorized();

/// @dev Interface that decentralised lottery implements
interface ILottery is IRNSourceCounsumer {
    /// @dev New ticket has been purchased by `user` for `drawId`
    /// @param drawId Draw for which the ticket was purchased
    /// @param user Address of the user buying ticket
    /// @param packedTicket Ticket represented as packed uint256
    event NewTicket(uint256 drawId, address user, uint256 packedTicket);

    /// @dev Fees are claimed from the lottery
    /// @param feeRecipiant Address that received the fees
    /// @param amount Total amount of fees claimed 
    event ClaimedFees(address feeRecipiant, uint256 amount);

    /// @dev Winnings are claimed from the lottery 
    /// @param user Address of the user claiming fees
    /// @param amount Total amount of winnings claimed
    event ClaimedWinnings(address user, uint256 amount);

    /// @dev Started executing draw for the drawId
    /// @param drawId Draw that is being executed
    event StartedExecutingDraw(uint256 drawId);

    /// @dev Triggered after finishing the draw process 
    /// @param drawId Draw being finished
    /// @param randomNumber Random number used for reconstructing ticket 
    /// @param winningTicket Winning ticket represented as packed uint256
    event FinishedExecutingDraw(uint256 drawId, uint256 randomNumber, uint256 winningTicket);

    /// @dev Triggered when reconstructed ticket contains duplicates
    /// @param drawId Draw being replayed 
    event RequestedReplayOfDraw(uint256 drawId);

    /// @dev Token to be used as reward token for the lottery
    /// It is used for both rewards and paying for tickets
    /// @return token Reward token address
    function rewardToken() external view returns (IERC20 token);

    /// @dev Price to pay for playing single game of lottery
    /// User pays it when registering the ticket for the game
    /// It is expressed in `rewardToken`
    /// @return price Price per ticket
    function ticketPrice() external view returns(uint256 price);

    /// @dev When registering ticket, user selcts total of `selectionSize` numbers
    /// @return size Count of numbers user picks for the ticket
    function selectionSize() external view returns(uint8 size);

    /// @dev When registering ticket, user selcts total of `selectionSize` numbers
    /// These numbers must be in range [0, `selectionMax`]
    /// @return max Max number user can pick
    function selectionMax() external view returns(uint8 max);

    /// @return period Period between 2 draws
    function drawPeriod() external view returns(uint256 period);

    /// @return lastDrawTime Timestamp of the last lottery draw
    function lastDrawTimestamp() external view returns(uint256 lastDrawTime);

    /// @return drawId Current game in progress
    function currentDraw() external view returns (uint256 drawId);

    /// @return source Address of the smart contract that is used as a source of random numbers
    function randomNumberSource() external view returns (IRNSource source);

    /// @dev Mapping from draw identifier to pot size
    /// @param drawId Draw identifier user buys ticket for
    /// @return size Current size of the loto pot to be split between winners
    function potSize(uint256 drawId) external view returns (uint256 size);

    /// @dev Ticket information
    /// @param drawId Id of the draw being checked
    /// @param ticket Ticket data (number selection packed in uint256)
    /// @return holders List of addresses holding tickets
    function ticketHolders(uint256 drawId, uint256 ticket) external view returns(address[] memory holders);

    /// @dev Ticket information
    /// @param user Address of the user being checked
    /// @param drawId Id of the draw being checked
    /// @return packedTickets List of packed tickets held by user
    function userTickets(address user, uint256 drawId) external view returns(uint256[] memory packedTickets);
    
    /// @dev Buy set of tickets for the upcoming lotteries
    /// `msg.sender` pays `ticketPrice` for each ticket and provides combination of numbers for each ticket
    /// Reverts in case of invalid number combination in any of the tickets
    /// Reverts in case of insufficient `rewardToken`(`tickets.length * ticketPrice`) in `msg.sender` account
    /// Requires approval to spend `msg.sender` `rewardToken` of at least `tickets.length * ticketPrice`
    /// @param drawIds Draw identifiers user buys ticket for
    /// @param tickets list of uint256 packed tickets
    function buyTickets(uint256[] calldata drawIds, uint256[] calldata tickets) external;

    /// @dev Transfers all `unclaimedFees` to `feeRecipient`
    function claimFees() external;

    /// @dev Transfer all winnings for `msg.sender`
    function claimWinnings() external;

    /// @dev Starts draw process
    /// Stops ticket sales
    /// Requests a random number from `randomNumberSource`
    function executeDraw() external;
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.17;

interface IRNSource {
    /// @dev Requests a new random number from the source
    /// @return requestId Identifer for random number request
    function requestRandomNumber() external returns (uint256 requestId);
}

interface IRNSourceCounsumer {
    /// @dev After requesting random number from IRNSource 
    /// this method will be called by IRNSource to deliver generated number
    /// @param randomNumber Generated random number
    function onRandomNumberFulfilled(uint256 randomNumber) external;
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity ^0.8.7;

import "src/interfaces/IRNSource.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

/// @dev Thrown if a wrong count of random numbers is received
/// @param requestId id of the request for random number
/// @param numbersCount count of random numbers received for the request
error WrongRandomNumberCountReceived(uint256 requestId, uint256 numbersCount);

/// @dev Non existant request, this should never happen as it means vrf reported number for a wrong request
/// @param requestId id of the request that is being checked
error RequestNotFound(uint256 requestId);

/// @dev Consumer is not allowed to request random numbers
/// @param consumer Address of consumer that tried requesting randim number
error UnauthorizedConsumer(address consumer);

interface IVRFv2RNSource is IRNSource {
    /// @dev Random number is requested from source
    /// @param requestId identifier of the request
    event RequestedRandomNumber(uint256 requestId);

    /// @dev Request is fulfilled
    /// @param requestId identifier of the request being fulfilled
    /// @param randomNumber random number generated
    event RequestFulfilled(uint256 requestId, uint256 randomNumber);

    /// @dev Request status structure
    struct RequestStatus {
        /// @dev Consumer that requested random number
        /// This is also used for checking if request exists by checking if consumer is zero address
        address consumer;
        /// @dev If request is fulfilled or not
        bool fulfilled;
        /// @dev Random number generated for particular request
        uint256 randomNumber;
    }

    /// @return subId Chainlink VRFv2 subscription id
    function subscriptionId() external returns (uint64 subId);

    /// @return coord Chainlink VRFv2 coordinator
    function coordinator() external returns (VRFCoordinatorV2Interface coord);

    /// @dev The gas lane to use, which specifies the maximum gas price to bump to.
    /// For a list of available gas lanes on each network,
    /// see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    /// @return _keyHash of gas lane to use
    function keyHash() external returns(bytes32 _keyHash);

    /// @return gasLimit Maximum amount of gas to be spent for fulfilling the request
    function callbackGasLimit() external returns (uint32 gasLimit);

    /// @return minConfirmations Minimum number of confirmations before request can be fulfilled
    function requestConfirmations() external returns (uint16 minConfirmations);

    /// @dev Authorises consumer to request random numbers from this source
    /// @param consumer Consumer beong authorised
    /// @param isAuthorised True if consumer is authorised, false otherwise
    function authoriseConsumer(address consumer, bool isAuthorised) external;

    /// @dev Checks if consumer is authorised to request random number
    /// @param consumer Address of consumer being checked
    /// @return isAuthorised True if consumer is authorised
    function registeredConsumer(address consumer) external returns (bool isAuthorised);

    /// @dev Queries random number request status
    /// @param requestId request identifier
    /// @return consumer Address of consumer that started request
    /// @return fulfilled If request was fulfilled
    /// @return randomNumber Generated random number if request is fulfilled
    function requests(uint256 requestId) external returns (address consumer, bool fulfilled, uint256 randomNumber);
}