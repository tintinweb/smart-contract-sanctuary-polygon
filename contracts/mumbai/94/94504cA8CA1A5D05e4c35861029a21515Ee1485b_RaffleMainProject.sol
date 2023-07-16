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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./RaffleVRF.sol";

error AdminNotFound();
error RoleCantBeEmpty();
error CommissionMustNotExceed100();
error InvalidAdminAddress();
error AdminDoesNotExist();
error InsufficientBalanceForCommissions();
error NoAdminsAvailable();
error Raffle_InvalidAmountOfTickets();
error Raffle_InvalidAmountInWei();
error RaffleAlreadyLocked();
error ThereIsNoPlayers();
error RaffleDidntReachSoftCap();
error RefundAlreadyRequested();
error RefundAlreadyClaimed();
error NoRefundAvailable();


/**
 * @title Raffle Main Project
 * @dev 
 * @
 */

contract RaffleMainProject is RaffleVRF{

    /* State Variables */
    //Owner address
    address public immutable owner;
    //RaffleVRF address
    address private raffleVRFAddress;
    
    /* Time control variables */    
    //Starting raffle time stamp
    uint256 private lastTimeStamp;
    //Time when raffle will be closed
    uint256 private raffleClosing;

    /* Payable variables */
    //Adm payment
    uint256 private amountToWithdraw;
    // Refund addresses
    address private refundWallet;
    //If true, refund already claimed
    bool private claimed;
    //Emercency variable
    bool private emergencyState;

    /* Raffle Variables */
    //Default
    uint256 private ticketCost;
    uint256 private prize;
    uint256 private softcap;

    //Others
    //Total number of entries
    uint256 public totalEntries;
    //Raffle Identifier
    uint256 public raffleId;
    //Counter to reallocation system
    uint private ticketReallocationCounter;
    //Address of the most recent raffle winner
    address payable public winner;

    
    /* Struct */
    // Struct to s_administration mapping
    struct ADMINS{
        address payable wallet;
        string name;
        string role;
        uint256 commission;
        bool isAdmin;
    }
    // Struct to Refund System
    struct RefundRequest{
        uint256 refundAmount;
        bool claimed;
    }
    //Struct realocation
    struct TicketReallocation {
        address participant;
        uint256 ticketCount;
        uint256 refundAmount;
        uint256 raffleId;
    }

    /* Array */
    //Storage for Admins Info
    address[] private adminAddresses;
    //Array of players who bought tickets
    address[] internal players;
    //Array of players for random selection
    address[] internal playerSelector;

    /* Mapping */
    //Storage for Admins Info
    mapping (address => ADMINS) private s_administration;
    // Mapping to store the count of entries per address
    mapping(address => uint256) public entryCount;
    // Storage for participants refund
    mapping(address => RefundRequest) private refundRequests;
    //Storage for recent Winners
    mapping (uint256 => address payable) public recentWinners;
    //Storage to transfer tickets
    mapping(uint256 => TicketReallocation) public ticketReallocationInfo;

    /* Events */
    event AdminADD(address indexed _wallet);
    event AdminUpdated(address indexed _wallet);
    event AdminRemoved(address indexed _wallet);
    event BalanceWithdrawn(address indexed admin, uint amountToWithdraw);
    event RaffleLocked();
    event RaffleCleared();
    event RaffeStarted(uint256 raffleId);
    event RafflePrizeSet(uint prize);
    event RaffleTicketCostSet(uint ticketCost);
    event NewEntry (address indexed player);
    event NewTicketBought(uint256 numberOfTickets);
    event ContractReseted();
    event WaitingForDraw();
    event RaffleCanceled();
    event WinnerPaid(address indexed winner, uint256 prize);
    event RefundClaimed(address indexed participant, uint256 amountToRefund);
    event TicketsReallocated(address indexed participant, uint256 ticketCount, uint256 refundAmount, uint256 nextRaffleId);
    event TicketsReallocatedToNextRaffle(address indexed participant, uint256 ticketCount, uint256 raffleId);

    /* Enum to RaffleStages */
    enum RaffleStage{
        Closed, //0
        Open, //1
        Canceled, //2
        Calculating, //3
        Emergency //4
    }

    RaffleStage private stage = RaffleStage.Closed;

    RaffleVRF private immutable raffleVRF;

    using SafeMath for uint256;

    /* CONSTRUCTOR */
    constructor(address vrfCoordinatorV2,
                bytes32 keyHash,
                uint64 subscriptionId,
                uint32 callbackGasLimit) RaffleVRF(vrfCoordinatorV2,
                                                            keyHash,
                                                            subscriptionId,
                                                            callbackGasLimit){
        owner = msg.sender;
        stage = RaffleStage.Closed;
        raffleVRF = RaffleVRF(0xe44a106C3f6DbAc30879bA6E1549C3EB81c0e216);
    }

    /* ADMINISTRATIVE FUNCTIONS */    
    /**
    * @dev Add a new admin to the administration list.
    * @param _wallet The wallet address of the new admin.
    * @param _name The name of the new admin.
    * @param _role The role of the new admin.
    * @param _commission The commission rate for the new admin.
    */
    function addAdmin(address payable _wallet, string memory _name, string memory _role, uint _commission) public safetyLock onlyOwner isAtStage(RaffleStage.Closed) {
        s_administration[_wallet] = ADMINS({
            wallet: _wallet,
            name: _name,
            role: _role,
            commission: _commission,
            isAdmin: true
        });

        require(_wallet != address(0), "WalletCantBeNull");
        require(bytes(_name).length != 0, "NameCantBeNull");
        require(bytes(_role).length != 0, "RoleCantBeNull");
        require(_commission != 0, "CommissionCantBeNull");

        adminAddresses.push(_wallet);
        emit AdminADD(_wallet);
    }

    //Shows the list of Admins
    function getAdmins() public view isAtStage(RaffleStage.Open) returns(ADMINS[] memory){
        uint256 numAdmins = adminAddresses.length;
        ADMINS[] memory admins = new ADMINS[](numAdmins);

        for (uint256 i = 0; i < numAdmins; i++) {
            address adminWallet = adminAddresses[i];
            admins[i] = s_administration[adminWallet];
        }
        return admins;
    }

    /**
    * @dev Update the information of an admin.
    * @param _wallet The wallet address of the admin to update.
    * @param _role The updated role of the admin.
    * @param _commission The updated commission rate for the admin.
    */
    function updateAdmin(address _wallet, string memory _role, uint256 _commission) public onlyOwner isAtStage(RaffleStage.Closed) {
        if (!s_administration[_wallet].isAdmin) {revert AdminNotFound();}
        if (bytes(_role).length == 0) {revert RoleCantBeEmpty();}
        if (_commission > 100) {revert CommissionMustNotExceed100();}

        s_administration[_wallet].role = _role;
        s_administration[_wallet].commission = _commission;

        emit AdminUpdated(_wallet);
    }

    /**
    * @dev Remove an admin from the administration list.
    * @param _wallet The wallet address of the admin to remove.
    */
    function removeAdmin(address _wallet) public onlyOwner isAtStage(RaffleStage.Closed) {
        if (_wallet == address(0)) {revert InvalidAdminAddress();}
        if (!s_administration[_wallet].isAdmin) {revert AdminDoesNotExist();}

        delete s_administration[_wallet];

        emit AdminRemoved(_wallet);
    }

    /**
    * @dev Withdraw the contract balance and distribute it among admins based on their commission rates.
    */
    function withdrawBalance() safetyLock isAtStage(RaffleStage.Closed) public onlyAdmins {
        if (amountToWithdraw == 0) {revert InsufficientBalanceForCommissions();}
        
        uint256 totalBalance = address(this).balance;
        uint256 totalCommission = 0;

        if (adminAddresses.length == 0) {revert NoAdminsAvailable();}
        
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            address payable admin = payable(adminAddresses[i]);
            totalCommission = totalCommission.add(s_administration[admin].commission);
        }
        
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            address payable admin = payable(adminAddresses[i]);
            uint256 adminCommission = s_administration[admin].commission;
            amountToWithdraw = totalBalance.mul(adminCommission).div(totalCommission);
            
            admin.transfer(amountToWithdraw);
            
            emit BalanceWithdrawn(admin, amountToWithdraw);
        }
    }
    /**
    * @dev Lock the raffle.
    * Only admins can call this function to lock the raffle.
    * Once locked, certain functions will not be executable.
    */
    function lockRaffle() public onlyAdmins {
        if (stage == RaffleStage.Emergency) {revert RaffleAlreadyLocked();}
        else {updateStage(RaffleStage.Emergency);
                emit RaffleLocked();
        }
    }
    
    /**
    * @dev Resume the raffle.
    * Only admins can call this function to resume the raffle after it has been paused.
    * Once resumed, all functions can be executed again.
    */
    function unlockRaffle() public onlyOwner {
        if (stage == RaffleStage.Emergency) {
            updateStage(RaffleStage.Canceled);
            emit RaffleCleared();
        }
    }

    /* COMMOM FUNCTIONS */
    // Returns the opening time of the raffle
    function openingTime() public view isAtStage(RaffleStage.Open) returns (uint256) {
        return lastTimeStamp;
    }

    // Returns the raffle closing time.
    function closingTime() public safetyLock isAtStage(RaffleStage.Open) returns (uint256) {
        if (block.timestamp > raffleClosing) {
            if (address(this).balance >= softcap) {
                updateStage(RaffleStage.Calculating);
                emit WaitingForDraw();
            } else {
                updateStage(RaffleStage.Canceled);
                emit RaffleCanceled();
            }
        }
        return raffleClosing;
    }

    // Block.timeStamp now
    function timeStampNow() public view returns (uint256) {
        return block.timestamp;
    }

    //Return raffle stage
    function getRaffleStage() public view returns (RaffleStage) {
        return stage;
    }

    //Return players array
    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    // Return the prize listed to the current Raffle
    function rafflePrize() public view isAtStage(RaffleStage.Open) returns(uint256){
        return prize;
    }

    //Return contract balance
    function getBalance() internal view safetyLock isAtStage(RaffleStage.Open) returns(uint256){
        return (address(this).balance);
    }

    //Updating Stages
    function updateStage(RaffleStage _stage) public onlyAdmins safetyLock isAtStage(RaffleStage.Open) {
        stage = _stage;
    }

    /* RAFFLE FUNCTIONS */
    /**
    * @dev Create a new raffle with updated fees, prize, and closing time.
    * @param feeToUpdate The updated entrance fee for the raffle.
    * @param newPrize The updated prize for the raffle.
    * @param newSoftcap The updated softcap for the raffle.
    * @param timeToClose The time duration for the raffle to close.
    */
    function createRaffle(uint256 feeToUpdate,
                          uint256 newPrize,
                          uint256 newSoftcap,
                          uint256 timeToClose) onlyAdmins safetyLock isAtStage(RaffleStage.Closed) public {       
        raffleId++;
        lastTimeStamp = block.timestamp;

        if (feeToUpdate != ticketCost) {ticketCost = feeToUpdate;}
        if (newSoftcap != softcap) {softcap = newSoftcap;}
        if (newPrize != prize) {prize = newPrize;}        

        raffleClosing = lastTimeStamp + timeToClose;
        require (timeToClose != 0, "Closing time must be set!");

        for (uint256 i = 0; i < ticketReallocationCounter; i++) {
            TicketReallocation storage reallocation = ticketReallocationInfo[i];

            if (reallocation.raffleId == raffleId) {
                entryCount[reallocation.participant] += reallocation.ticketCount;

                emit TicketsReallocatedToNextRaffle(reallocation.participant, reallocation.ticketCount, raffleId);
            }
        }
        updateStage(RaffleStage.Open);

        emit RaffeStarted(raffleId);
        emit RafflePrizeSet(prize);
        emit RaffleTicketCostSet(ticketCost);
    }

    /**
    * @dev Buy raffle tickets.
    * @param numberOfTickets The number of tickets to buy.
    */
    function buyTicket(uint256 numberOfTickets) public payable safetyLock isAtStage(RaffleStage.Open) {
    require(block.timestamp < raffleClosing, "Check the closing time!");
        
        if(numberOfTickets <= 0){
            revert Raffle_InvalidAmountOfTickets();
            }

        uint256 ticketCostTotal = SafeMath.mul(ticketCost, numberOfTickets);
        require(msg.value == ticketCostTotal, "Incorrect amount sent");

        entryCount[msg.sender] = SafeMath.add(entryCount[msg.sender], numberOfTickets);
        totalEntries = SafeMath.add(totalEntries, numberOfTickets);

        if (!isPlayer(msg.sender)) {
            players.push(msg.sender);
        }
        
        for (uint256 i = 0; i < numberOfTickets; i++){
            playerSelector.push(msg.sender);
        }

        emit NewEntry(msg.sender);
        emit NewTicketBought(numberOfTickets);
    }

    //Validates if the buyer is already in players array
    function isPlayer(address participant) private view returns (bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == participant) {
                return true;
            }
        }
        return false;
    }

    //Select Winner Function
    function selectWinner() public safetyLock onlyAdmins isAtStage(RaffleStage.Calculating){
        require (playerSelector.length > 0, "There is no players");
        if(address(this).balance < softcap){
            revert RaffleDidntReachSoftCap();
        }

        uint256 requestId = RaffleVRF(raffleVRFAddress).requestRandomWords();

        emit RequestedRaffleWinner(requestId);
    }

    function drawResult(uint256 requestId) public onlyAdmins safetyLock isAtStage(RaffleStage.Calculating) returns (address) {
        require(s_requests[requestId].fulfilled, "Request not fulfilled");
        require(s_requests[requestId].randomWords.length > 0, "Random words not available");

        uint256 winnerIndex = s_requests[requestId].randomWords[0] % playerSelector.length;
        address winnerAddress  = playerSelector[winnerIndex];
        winner = payable(winnerAddress);

        return winnerAddress;
    } 

    /* PAY WINNER FUNCTION */
    /**
    * @dev Pay the raffle winner.
    */
    function payWinner() public onlyAdmins safetyLock isAtStage(RaffleStage.Calculating) {
        require(winner != address(0), "No winner selected");

        uint256 prizeAmount = prize;

        if (prizeAmount > 0) {
            recentWinners[raffleId] = payable(winner);
            (bool success, ) = winner.call{value: prizeAmount}("");
            require(success, "Transfer failed");

            emit WinnerPaid(winner, prizeAmount);
        }
        else {recentWinners[raffleId] = payable(address(0));}
    }

    /* REFUND FUNCTIONS */
    /**
    * @dev Request a refund for the participant in case of a canceled raffle.
    */
    function requestRefund() public safetyLock isAtStage(RaffleStage.Canceled) {
        if (refundRequests[msg.sender].refundAmount != 0) {revert RefundAlreadyRequested();}

        if (refundRequests[msg.sender].claimed) {revert RefundAlreadyClaimed();}

        uint256 refundAmount = calculateRefundAmount(msg.sender);
        if (refundAmount == 0) {revert NoRefundAvailable();}

        refundRequests[msg.sender].refundAmount = refundAmount;
    }

    // Search for the total spend with Raffle Tickets
    function calculateRefundAmount(address participant) internal view safetyLock isAtStage(RaffleStage.Canceled) returns (uint256) {
        uint256 totalAmountSpent = 0;

        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i];
            uint256 numberOfTickets = entryCount[player];
            if (player == participant && numberOfTickets > 0) {totalAmountSpent = totalAmountSpent.add(numberOfTickets.mul(ticketCost));}
        }
        return totalAmountSpent;
    }

    /**
    * @dev Claim the refund amount for a participant.
    */
    function claimRefund() public safetyLock isAtStage(RaffleStage.Canceled){
        if (refundRequests[msg.sender].refundAmount == 0) {revert NoRefundAvailable();}

        if (refundRequests[msg.sender].claimed) {revert RefundAlreadyClaimed();
        }

        uint256 amountToRefund = refundRequests[msg.sender].refundAmount;
        refundRequests[msg.sender].refundAmount = 0;
        refundRequests[msg.sender].claimed = true;

        payable(msg.sender).transfer(amountToRefund);
    }

    /**
    * @dev Refund all participants who did not claim their refunds before the refund deadline.
    */
    function refundAllForgottenParticipants() public onlyAdmins safetyLock isAtStage(RaffleStage.Canceled) {
        for (uint256 i = 0; i < players.length; i++) {
            address participant = players[i];

            if (refundRequests[participant].refundAmount > 0 && !refundRequests[participant].claimed) {
                uint256 amountToRefund = refundRequests[participant].refundAmount;
                refundRequests[participant].refundAmount = 0;
                refundRequests[participant].claimed = true;

                (bool success, ) = payable(participant).call{value: amountToRefund}("");
                require(success, "Transfer failed");

                emit RefundClaimed(participant, amountToRefund);
            }
        }
    }

    /**
    * @dev Reallocate tickets to the next raffle for participants who did not request a refund.
    * @param nextRaffleId The ID of the next raffle to reallocate tickets.
    */
    function reallocateTicketsToNextRaffle(uint256 nextRaffleId) public onlyAdmins safetyLock isAtStage(RaffleStage.Canceled) {
        for (uint256 i = 0; i < players.length; i++) {
            address participant = players[i];

            if (refundRequests[participant].refundAmount > 0 && !refundRequests[participant].claimed) {
                uint256 ticketCount = entryCount[participant];
                uint256 refundAmount = refundRequests[participant].refundAmount;

                uint256 reallocationIndex = ticketReallocationCounter;
                ticketReallocationInfo[reallocationIndex] = TicketReallocation(participant, ticketCount, refundAmount, nextRaffleId);
                ticketReallocationCounter++;

                emit TicketsReallocated(participant, ticketCount, refundAmount, nextRaffleId);
            }
        }
    }

    /**
    * @dev Reset the contract to its initial state.
    * Only the contract owner can call this function.
    */
    function resetContract() public onlyAdmins safetyLock isAtStage(RaffleStage.Closed) {
        delete playerSelector;
        delete players;
        totalEntries = 0;
        ticketCost = ticketCost;
        prize = prize;
        softcap = softcap;
        stage = RaffleStage.Closed;

        emit ContractReseted();
    }

    /* MODIFIERS */
    //onlyOwner
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function!") ;
        _;
    }
    //onlyAdmins
    modifier onlyAdmins {
        require(s_administration[msg.sender].isAdmin, "Only admin and owner can call this function!");
        _;
    }
    //Stage validation
    modifier isAtStage(RaffleStage _stage){
        require(stage == _stage, "Not at correct stage!");
        _;
    }
    /**
    * @dev Modifier that checks if the raffle is not paused before executing the function.
    * The owner can still execute transactions even during the paused period.
    */
    modifier safetyLock() {
        require(!emergencyState || msg.sender == owner, "Raffle is LOCKED");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

error Raffle_IdNotRequested();
error RaffleIsLocked();
error RaffleUnlocked();

contract RaffleVRF is VRFConsumerBaseV2{

/* Chainlink VRF Tools*/
    uint64 private immutable s_subscriptionId;
    uint[] public requestIds;
    uint public lastRequestId;
    bytes32 private immutable keyHash;
    uint32 private  immutable callbackGasLimit;

    uint16 private constant requestConfirmations = 3;
    uint32 private constant numWords = 1;

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    mapping(uint256 => RequestStatus) public s_requests;

    VRFCoordinatorV2Interface private immutable COORDINATOR;

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    event RequestedRaffleWinner(uint256 requestId);

    constructor(address vrfCoordinatorV2, bytes32 i_keyHash, uint64 subscriptionId, uint32 i_callbackGasLimit) VRFConsumerBaseV2(vrfCoordinatorV2){
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        keyHash = i_keyHash;
        s_subscriptionId = subscriptionId;
        callbackGasLimit = i_callbackGasLimit;    
    }

    /* VRF FUNCTIONS */
    /**
    * @dev Request random words from the VRF coordinator to determine the raffle winner.
    * @return requestId The ID of the random word request.
    */
    function requestRandomWords() external returns (uint256 requestId){
        requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);
        
        s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
        requestIds.push(requestId);
        lastRequestId = requestId;

        emit RequestSent(requestId, numWords);

        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {

        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        emit RequestFulfilled(_requestId, _randomWords);
    }
    
    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }


}