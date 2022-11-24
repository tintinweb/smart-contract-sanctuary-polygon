// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./Hilow.sol";
import "./CardsHolding.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract Counter is AutomationCompatibleInterface {
    /**
     * Public counter variable
     */
    uint256 public counter;
    Hilow public hillowContract;
    CardsHolding public cardsHoldingContract;
    address public _owner;
    /**
     * Use an interval in seconds and a timestamp to slow execution of Upkeep
     */
    uint256 public immutable interval;
    uint256 public lastTimeStamp;

    constructor(
        uint256 updateInterval,
        address _hilloAddress,
        address _cardholding
    ) {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        hillowContract = Hilow(payable(_hilloAddress));
        cardsHoldingContract = CardsHolding(payable(_cardholding));
        counter = 0;
        _owner = msg.sender;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool,
            bytes memory /* performData */
        )
    {
        bool upkeepNeeded = true;
        uint256 length = cardsHoldingContract.getStoredCardsLength();
        if (length > 2999) {
            upkeepNeeded = false;
        }
        return (upkeepNeeded, "");
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        hillowContract.initialCardLoad();
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    function setHiContractAddress(address _hicontract) external {
        require(msg.sender == _owner, "only owner can cal this fucntion");
        require(_hicontract != address(0), "Invalid address");
        hillowContract = Hilow(payable(_hicontract));
    }

    function updateCardHoldingaddress(address _cardContract) external {
        require(msg.sender == _owner, "only owner can cal this fucntion");
        require(_cardContract != address(0), "Invalid address");
        cardsHoldingContract = CardsHolding(payable(_cardContract));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./CardsHoldingInterface.sol";

contract CardsHolding is CardsHoldingInterface {
    address hiContract;
    uint256[] internal cards;
    uint256[] internal firstFlipNumbers;
    uint256[] private firstFlipCards = [
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        7,
        8,
        8,
        8,
        8,
        8,
        8,
        8,
        8,
        8,
        8,
        6,
        6,
        6,
        6,
        6,
        6,
        6,
        6,
        6,
        6,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        9,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        5,
        4,
        4,
        4,
        4,
        4,
        4,
        10,
        10,
        10,
        10,
        10,
        10,
        3,
        3,
        3,
        3,
        3,
        11,
        11,
        11,
        11,
        11,
        2,
        2,
        2,
        2,
        12,
        12,
        12,
        12,
        1,
        13,
        1,
        13
    ];
    address _owner;

    // uint32 private MAX_WORDS;
    // uint32 private BUFFER_WORDS;

    // function getNextCard()
    //     external
    //     returns (uint256 card, bool shouldTriggerDraw)
    // {
    //     if (_currentCard.current() > BUFFER_WORDS) {
    //         shouldTriggerDraw = true;
    //     }
    //     if (_currentCard.current() >= MAX_WORDS) {
    //         _currentCard.reset();
    //     }
    //     uint256 currentCard = _currentCard.current();
    //     _currentCard.increment();
    //     card = cards[currentCard];
    // }

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "only owner can call this function");
        _;
    }

    //need to understand buffer concept
    function getNextCard() external override returns (uint256) {
        require(cards.length > 0, "Not enough cards to draw");
        uint256 card = cards[cards.length - 1];
        cards.pop();
        return card;
    }

    // function storeCards(uint256[] memory cardValues) external {
    //     for (uint256 index = 0; index < MAX_WORDS; index++) {
    //         cards[index] = (cardValues[index] % 13) + 1;
    //     }
    //     _currentCard.reset();
    // }

    function storeCards(uint256[] memory cardValues) external override {
        // require(hiContract != address(0), "Invalid address");
        // require(
        //     msg.sender == hiContract,
        //     "Only authorised address can call this function"
        // );
        require(cardValues.length > 0, "Plese ensure correct input");

        for (uint256 index = 0; index < cardValues.length; index++) {
            cards.push((cardValues[index] % 13) + 1);
            firstFlipNumbers.push((cardValues[index] % 100) + 1);
        }
    }

    function getFirstFlipCard() external override returns (uint256) {
        require(firstFlipNumbers.length > 0, "Not enough cards to draw");
        require(firstFlipNumbers.length - 1 != 0, "Plese ensure enough cards");
        uint256 card = firstFlipCards[
            firstFlipNumbers[firstFlipNumbers.length - 1]
        ];
        firstFlipNumbers.pop();
        return card;
    }

    function setHiAddress(address _caller) public onlyOwner {
        require(_caller != address(0), "Invalid address");
        hiContract = _caller;
    }

    // function setAutomationAddress(address _automation) public onlyOwner {
    //     require(_automation != address(0), "Invalid address");
    //     hiContract = _automation;
    // }

    function getStoredCardsLength() external view returns (uint256 length) {
        length = cards.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface CardsHoldingInterface {
    function getNextCard() external returns (uint256 card);

    function storeCards(uint256[] memory cardValues) external;

    function getFirstFlipCard() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PayableContract.sol";
import "./CardsHoldingInterface.sol";

contract Hilow is VRFConsumerBaseV2, PayableHilowContract, Ownable {
    struct Card {
        uint256 value;
    }

    struct GameCards {
        Card firstDraw;
        Card secondDraw;
        Card thirdDraw;
    }

    struct Game {
        GameCards cards;
        uint256 betAmount;
        bool firstPrediction;
        bool secondPrediction;
    }
    address public AutomationAddress;
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address constant vrfCoordinator =
        0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    bytes32 constant s_keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    // address constant vrfCoordinator =
    //     0xAE975071Be8F8eE67addBC1A82488F1C24858067;
    // bytes32 constant s_keyHash =
    //     0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd;

    uint32 constant callbackGasLimit = 1000000;
    uint16 constant requestConfirmations = 13;

    uint32 private MAX_WORDS;
    uint256 MAX_BET_AMOUNT = 5 * 10**18;
    PayableHilowContract teamContract;
    PayableHilowContract supportersContract;
    CardsHoldingInterface cardsHolding;

    Card placeholderCard = Card(0);
    GameCards placeholderGameCards =
        GameCards(placeholderCard, placeholderCard, placeholderCard);
    Game placeholderGame = Game(placeholderGameCards, 0, false, false);
    mapping(uint256 => uint256) private LOW_BET_PAYOFFS;
    mapping(uint256 => uint256) private HIGH_BET_PAYOFFS;
    mapping(address => Game) private gamesByAddr;

    event CardDrawn(address indexed player, uint256 firstDrawCard);
    event FirstBetMade(
        address indexed player,
        uint256 firstDrawCard,
        uint256 secondDrawCard,
        bool isWin
    );
    event GameFinished(
        address indexed player,
        uint256 firstDrawCard,
        uint256 secondDrawCard,
        uint256 thirdDrawCard,
        bool isWin,
        uint256 payoutMultiplier,
        uint256 payoutAmount
    );
    event DealerTipped(address indexed tipper, uint256 amount);

    constructor(
        uint64 subscriptionId,
        address payable _teamPayoutContractAddress,
        address payable _supportersPayoutContractAddress,
        address _cardsHoldingContractAddress,
        uint32 maxWords
    ) payable VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        teamContract = PayableHilowContract(_teamPayoutContractAddress);
        supportersContract = PayableHilowContract(
            _supportersPayoutContractAddress
        );
        cardsHolding = CardsHoldingInterface(_cardsHoldingContractAddress);
        MAX_WORDS = maxWords;

        setBetAmounts();
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        address hilowOwner = owner();
        (bool success, bytes memory data) = payable(hilowOwner).call{
            value: balance
        }("Withdrawing funds");
        require(success, "Withdraw failed");
    }

    function viewGame(address addr)
        public
        view
        onlyOwner
        returns (Game memory)
    {
        return gamesByAddr[addr];
    }

    function viewPayoffForBet(bool higher, uint256 firstCard)
        public
        view
        returns (uint256)
    {
        require(firstCard >= 1 && firstCard <= 13, "Invalid first card");
        if (higher) return HIGH_BET_PAYOFFS[firstCard];
        else return LOW_BET_PAYOFFS[firstCard];
    }

    function tip() public payable {
        emit DealerTipped(msg.sender, msg.value);
    }

    function drawBulkRandomCards() internal returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            MAX_WORDS
        );
    }

    //Do we need this function
    function initialCardLoad() public {
        require(
            AutomationAddress != address(0),
            "AutomationAddress null, please ask admin to set the address"
        );
        require(
            AutomationAddress == msg.sender,
            " Only authorised address can call the function"
        );
        drawBulkRandomCards();
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        cardsHolding.storeCards(randomWords);
    }

    function isGameAlreadyStarted() public view returns (bool) {
        GameCards memory currentGame = gamesByAddr[msg.sender].cards;
        if (
            (currentGame.firstDraw.value > 0 &&
                currentGame.thirdDraw.value == 0)
        ) {
            return true;
        }
        return false;
    }

    function getActiveGame() public view returns (bool, Game memory) {
        if (isGameAlreadyStarted()) {
            return (true, gamesByAddr[msg.sender]);
        }
        return (false, placeholderGame);
    }

    function drawCard() public {
        require(!isGameAlreadyStarted(), "Game already started");

        uint256 firstDrawValue;
        bool shouldTriggerDraw;
        (firstDrawValue) = cardsHolding.getFirstFlipCard();
        Card memory firstDraw = Card(firstDrawValue);

        //check this fucntion call, Dheeraj
        // if (shouldTriggerDraw) {
        //     drawBulkRandomCards();
        // }

        GameCards memory gameCards = GameCards(
            firstDraw,
            placeholderCard,
            placeholderCard
        );
        Game memory game = Game(gameCards, 0, false, false);
        gamesByAddr[msg.sender] = game;
        emit CardDrawn(msg.sender, firstDraw.value);
    }

    function checkWin(
        uint256 cardOne,
        uint256 cardTwo,
        bool higher
    ) private pure returns (bool) {
        bool isWin;
        if (higher) {
            if (cardOne == 1) {
                if (cardTwo > cardOne) {
                    isWin = true;
                }
            } else if (cardOne == 13) {
                if (cardTwo == cardOne) {
                    isWin = true;
                }
            } else {
                if (cardTwo >= cardOne) {
                    isWin = true;
                }
            }
        } else {
            if (cardOne == 1) {
                if (cardTwo == cardOne) {
                    isWin = true;
                }
            } else if (cardOne == 13) {
                if (cardTwo < cardOne) {
                    isWin = true;
                }
            } else {
                if (cardTwo <= cardOne) {
                    isWin = true;
                }
            }
        }

        return isWin;
    }

    function getPayoutMultiplier(uint256 cardOne, bool higher)
        private
        view
        returns (uint256)
    {
        uint256 multiplier;
        if (higher) {
            multiplier = HIGH_BET_PAYOFFS[cardOne];
        } else {
            multiplier = LOW_BET_PAYOFFS[cardOne];
        }

        return multiplier;
    }

    function makeFirstBet(bool higher) public payable {
        require(msg.value <= MAX_BET_AMOUNT, "Max bet amount exceeded");
        Game memory currentGame = gamesByAddr[msg.sender];
        GameCards memory currentGameCards = currentGame.cards;
        require(
            currentGameCards.firstDraw.value > 0,
            "First card should be drawn for the game"
        );
        require(
            currentGameCards.secondDraw.value == 0,
            "Second card has already been drawn for the game"
        );
        payCommission();

        uint256 secondDrawValue;
        bool shouldTriggerDraw;
        (secondDrawValue) = cardsHolding.getNextCard();
        Card memory secondDraw = Card(secondDrawValue);
        // if (shouldTriggerDraw) {
        //     drawBulkRandomCards();
        // }

        currentGameCards.secondDraw = secondDraw;
        currentGame.betAmount = msg.value;
        currentGame.firstPrediction = higher;
        gamesByAddr[msg.sender] = Game(
            currentGameCards,
            currentGame.betAmount,
            currentGame.firstPrediction,
            false
        );

        bool isWin;
        isWin = checkWin(
            currentGameCards.firstDraw.value,
            currentGameCards.secondDraw.value,
            higher
        );
        if (!isWin) {
            gamesByAddr[msg.sender] = placeholderGame;
        }

        emit FirstBetMade(
            msg.sender,
            currentGameCards.firstDraw.value,
            currentGameCards.secondDraw.value,
            isWin
        );
    }

    function makeSecondBet(bool higher) public {
        Game memory currentGame = gamesByAddr[msg.sender];
        GameCards memory currentGameCards = currentGame.cards;
        require(
            currentGameCards.firstDraw.value > 0 &&
                currentGameCards.secondDraw.value > 0,
            "First and second card should be drawn for the game"
        );
        require(
            currentGameCards.thirdDraw.value == 0,
            "Third card has already been drawn for the game"
        );

        uint256 thirdDrawValue;
        bool shouldTriggerDraw;
        (thirdDrawValue) = cardsHolding.getNextCard();
        Card memory thirdDraw = Card(thirdDrawValue);
        // if (shouldTriggerDraw) {
        //     drawBulkRandomCards();
        // }

        currentGameCards.thirdDraw = thirdDraw;
        currentGame.secondPrediction = higher;
        gamesByAddr[msg.sender] = Game(
            currentGameCards,
            currentGame.betAmount,
            currentGame.firstPrediction,
            currentGame.secondPrediction
        );

        bool isFirstWin = checkWin(
            currentGameCards.firstDraw.value,
            currentGameCards.secondDraw.value,
            currentGame.firstPrediction
        );
        bool isSecondWin = checkWin(
            currentGameCards.secondDraw.value,
            currentGameCards.thirdDraw.value,
            currentGame.secondPrediction
        );

        uint256 payoutMultiplier;
        uint256 payoutAmount;

        if (isFirstWin && isSecondWin) {
            uint256 multiplier1 = getPayoutMultiplier(
                currentGameCards.firstDraw.value,
                currentGame.firstPrediction
            );
            uint256 multiplier2 = getPayoutMultiplier(
                currentGameCards.secondDraw.value,
                currentGame.secondPrediction
            );
            payoutAmount =
                (currentGame.betAmount * multiplier1 * multiplier2) /
                10000;
            (bool success, bytes memory data) = payable(msg.sender).call{
                value: payoutAmount
            }("Sending payout");
            require(success, "Payout failed");
        }

        emit GameFinished(
            msg.sender,
            currentGameCards.firstDraw.value,
            currentGameCards.secondDraw.value,
            currentGameCards.thirdDraw.value,
            isSecondWin,
            payoutMultiplier,
            payoutAmount
        );
    }

    function payCommission() internal {
        uint256 teamCommission = SafeMath.div(SafeMath.mul(msg.value, 1), 100); // 1% to team
        uint256 supportersCommission = SafeMath.div(
            SafeMath.mul(msg.value, 4),
            100
        ); // 4% to supporters

        bool tsuccess = teamContract.sendFunds{value: teamCommission}();
        require(tsuccess, "Team commission payout failed.");
        bool ssuccess = supportersContract.sendFunds{
            value: supportersCommission
        }();
        require(ssuccess, "Supporters commission payout failed.");
    }

    function setAtomationAddress(address _automation) public onlyOwner {
        require(_automation != address(0), "Invalid address");

        AutomationAddress = _automation;
    }

    function setCardsHoldingAddress(address _cardholding) public onlyOwner {
        require(_cardholding != address(0), "Invalid address");

        cardsHolding = CardsHoldingInterface(_cardholding);
    }

    function setBetAmounts() private {
        // Set low bet payoffs
        LOW_BET_PAYOFFS[1] = 200;
        LOW_BET_PAYOFFS[2] = 192;
        LOW_BET_PAYOFFS[3] = 184;
        LOW_BET_PAYOFFS[4] = 176;
        LOW_BET_PAYOFFS[5] = 169;
        LOW_BET_PAYOFFS[6] = 161;
        LOW_BET_PAYOFFS[7] = 153;
        LOW_BET_PAYOFFS[8] = 146;
        LOW_BET_PAYOFFS[9] = 138;
        LOW_BET_PAYOFFS[10] = 130;
        LOW_BET_PAYOFFS[11] = 123;
        LOW_BET_PAYOFFS[12] = 115;
        LOW_BET_PAYOFFS[13] = 100;

        // Set low bet payoffs
        HIGH_BET_PAYOFFS[1] = 100;
        HIGH_BET_PAYOFFS[2] = 115;
        HIGH_BET_PAYOFFS[3] = 123;
        HIGH_BET_PAYOFFS[4] = 130;
        HIGH_BET_PAYOFFS[5] = 138;
        HIGH_BET_PAYOFFS[6] = 146;
        HIGH_BET_PAYOFFS[7] = 153;
        HIGH_BET_PAYOFFS[8] = 161;
        HIGH_BET_PAYOFFS[9] = 169;
        HIGH_BET_PAYOFFS[10] = 176;
        HIGH_BET_PAYOFFS[11] = 184;
        HIGH_BET_PAYOFFS[12] = 192;
        HIGH_BET_PAYOFFS[13] = 200;
    }

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PayableHilowContract {
    address _owner;

    constructor() {
        _owner = payable(msg.sender);
    }

    function sendFunds() external payable returns (bool) {
        return true;
    }

    function withdrawAll() external {
        require(msg.sender == _owner, "onlyOwner can call withdraw");
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }

    function changeOwner(address _newOwner) external {
        require(
            msg.sender == _owner,
            "Only owner can change the exsistign owner"
        );

        _owner = _newOwner;
    }

    // fallback() external payable {}

    // receive() external payable {
    //     // React to receiving ether
    // }
}