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
import "./RaffleVRFv2Consumer.sol";

error RefundAlreadyRequested();
error RefundAlreadyClaimed();
error NoRefundAvailable();


/**
 * @title Raffle Main Project
 * @dev 
 * @
 */

contract RaffleMainProject {

    /* State Variables */
    //Owner address
    address private owner;
    /* Time control variables */    
    //Starting raffle time stamp
    uint256 private lastTimeStamp;
    //Time when raffle will be closed
    uint256 private raffleClosing;

    /* Payable variables */
    // Refund addresses
    address private refundWallet;
    //If true, refund already claimed
    bool private claimed;
    //Emercency variable
    bool private emergencyState;

    /* Raffle Variables */
    //Default
    uint256 public ticketCost;
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
    // Storage for participants' refund
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
    event NewEntry(address indexed player);
    event NewTicketBought(uint256 numberOfTickets);
    event ContractReseted();
    event WaitingForDraw();
    event RaffleCanceled();
    event RequestedRaffleWinner();
    event WinnerSelected(uint winnerIndex, address winnerAddress, uint256 randomValue);
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

    RaffleVRFv2Consumer vrfv2consumer = RaffleVRFv2Consumer (0xf2d908789d645d031028efd37e2d73281B07C827);

    using SafeMath for uint256;

    /**
     * @dev Constructor function to initialize the contract.
     */
    constructor() {
        owner = msg.sender;
        stage = RaffleStage.Closed;
    }

    /* ADMINISTRATIVE FUNCTIONS */    
    /**
    * @dev Add a new admin to the administration list.
    * This function can only be called when the raffle is in the 'Closed' stage, meaning that no raffle is currently active.
    * It allows the contract owner to add a new admin with specific privileges for managing future raffles.
    * The provided parameters must meet certain requirements:
    * - The '_wallet' address must not be null (0x0).
    * - The '_name' and '_role' strings must not be empty.
    * - The '_commission' rate must be greater than 0 and cannot exceed 100, as it represents a percentage.
    *   The total commission of all admins combined cannot exceed 100% to ensure fairness and sustainability of the raffle.
    * If the address provided is already registered as an admin, the function will revert to prevent duplicate entries.
    * The total commission of all admins is calculated, including the new admin's commission, to ensure it does not exceed 100%.
    * Once all requirements are met, the new admin's details are added to the 's_administration' mapping and the 'adminAddresses' array.
    * Emits an 'AdminADD' event to signal the addition of a new admin.
    * @param _wallet The wallet address of the new admin.
    * @param _name The name of the new admin.
    * @param _role The role of the new admin.
    * @param _commission The commission rate for the new admin.
    */
    function addAdmin(address payable _wallet, string memory _name, string memory _role, uint _commission) public safetyLock onlyOwner {
        require(stage == RaffleStage.Closed, "Raffle must be closed to add Admins");
        require(_wallet != address(0), "WalletCantBeNull");
        require(bytes(_name).length != 0, "NameCantBeNull");
        require(bytes(_role).length != 0, "RoleCantBeNull");
        require(_commission > 0 && _commission <= 100, "Commission must be between 1 and 100");

        // Check if the address is not already an admin.
        require(!s_administration[_wallet].isAdmin, "Admin already registered");

        // Calculate the new total commission with the addition of the new admin's commission.
        uint256 totalCommission = 0;
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            address adminAddress = adminAddresses[i];
            totalCommission = totalCommission.add(s_administration[adminAddress].commission);
        }
        totalCommission = totalCommission.add(_commission);

        require(totalCommission <= 100, "Total commission cannot exceed 100%");

        s_administration[_wallet] = ADMINS({
            wallet: _wallet,
            name: _name,
            role: _role,
            commission: _commission,
            isAdmin: true
        });
        adminAddresses.push(_wallet);

        emit AdminADD(_wallet);
    }


    //Shows the list of Admins
    function getAdmins() public view returns(ADMINS[] memory){
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
    function updateAdmin(address _wallet, string memory _role, uint256 _commission) public onlyOwner {
        require(stage == RaffleStage.Closed, "Raffle must be closed to update Admins infos");

        require(s_administration[_wallet].isAdmin, "Admin not found");
        require(bytes(_role).length != 0, "Role can't be empty");
        require(_commission < 100, "Commission can't exceed 100%");

        s_administration[_wallet].role = _role;
        s_administration[_wallet].commission = _commission;

        emit AdminUpdated(_wallet);
    }

    /**
    * @dev Remove an admin from the administration list.
    * @param _wallet The wallet address of the admin to remove.
    */
    function removeAdmin(address _wallet) public onlyOwner {
        require(stage == RaffleStage.Closed, "Raffle must be closed to remove Admins");

        require(_wallet != address(0),"Invalid Admin address!");
        require(s_administration[_wallet].isAdmin, "Admin does not exist!");

        delete s_administration[_wallet];

        emit AdminRemoved(_wallet);
    }

    /**
    * @dev Withdraw the contract balance and distribute it among admins based on their commission rates.
    * This function allows admins to withdraw their earned commissions from the raffle contract's balance
    * after the raffle has been closed ('RaffleStage.Closed'). Only users with admin privileges can call this function.
    * The function first checks if the raffle is in the 'RaffleStage.Closed' stage; otherwise, it reverts with an error message.
    * It also verifies if there are admins available to distribute the balance; otherwise, it reverts with an error message.
    * The function calculates the total commission earned by all admins based on their individual commission rates.
    * It then calculates the total balance available in the contract.
    * For each admin, the function calculates the amount they are entitled to based on their commission rate and the total commission earned.
    * It ensures that the amount to withdraw is greater than 0; otherwise, it reverts with an error message.
    * The function then transfers the calculated amount to each admin and emits the 'BalanceWithdrawn' event for each withdrawal.
    */
    function withdrawBalance() safetyLock public onlyAdmins {
        require(stage == RaffleStage.Closed, "Raffle must be closed to withdraw balance");
        require(adminAddresses.length > 0,"No admins available!");
        
        uint256 totalCommission = 0;        
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            address payable admin = payable(adminAddresses[i]);
            totalCommission = totalCommission.add(s_administration[admin].commission);
        }

        uint256 totalBalance = address(this).balance;
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            address payable admin = payable(adminAddresses[i]);
            uint256 adminCommission = s_administration[admin].commission;
            uint256 amountToWithdraw = totalBalance.mul(adminCommission).div(totalCommission);

            require(amountToWithdraw > 0, "Insufficient balance for commissions!");

            (bool success, ) = admin.call{value: amountToWithdraw}("");
            require(success, "Transfer failed");
            
            emit BalanceWithdrawn(admin, amountToWithdraw);
        }
    }

    /**
    * @dev Lock the raffle.
    * Only admins can call this function to lock the raffle.
    * Once locked, certain functions will not be executable.
    */
    function lockRaffle() public onlyAdmins {
        require (emergencyState == false, "Already Locked!");
        
        emergencyState = true;

        stage = RaffleStage.Emergency;
        
        emit RaffleLocked();
        
    }
    
    /**
    * @dev Resume the raffle.
    * Only the owner can call this function to resume the raffle after it has been paused.
    * Once resumed, all functions can be executed again.
    */
    function unlockRaffle() public onlyOwner {
        require(emergencyState == true, "It's not locked!");

        emergencyState = false;

        updateStage(RaffleStage.Canceled);

        emit RaffleCleared();
    }

    /* COMMOM FUNCTIONS */
    // Returns the opening time of the raffle
    function openingTime() public view returns (uint256) {
        require(stage == RaffleStage.Open, "Raffle must be Open to see the opening time");
        return lastTimeStamp;
    }

    /**
    * @dev Returns the raffle closing time.
    * This function can be called by anyone to check the closing time of the raffle.
    * It first checks if the raffle is in the 'RaffleStage.Open' stage; otherwise, it reverts with an error message.
    * If the current block timestamp is greater than the raffle closing time, the function checks the raffle's balance.
    * If the balance is greater than or equal to the softcap, it means the minimum number of tickets has been sold,
    * and the raffle can proceed to the 'RaffleStage.Calculating' stage. The function then calls 'updateStage' to set the new stage
    * and emits the 'WaitingForDraw' event to notify participants that the raffle is waiting for the winner to be drawn.
    * If the balance is less than the softcap, it means the minimum number of tickets has not been sold,
    * and the raffle is canceled. The function calls 'updateStage' to set the new stage and emits the 'RaffleCanceled' event.
    * If the current block timestamp is still before the raffle closing time, the function simply returns the raffle closing time.
    */
    function closingTime() public returns (uint256 status) {
        require(stage == RaffleStage.Open, "Raffle must be Open to see the closing time");
        if (block.timestamp > raffleClosing) {
            if (address(this).balance >= softcap) {
                updateStage(RaffleStage.Calculating);
                emit WaitingForDraw();
            }   else {
                    updateStage(RaffleStage.Canceled);
                    emit RaffleCanceled();
                }
                
        } else {return raffleClosing;}     
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
    function rafflePrize() public view returns(uint256){
        require(stage == RaffleStage.Open, "Raffle must be Open to see the prize");

        return prize;
    }

    //Return contract balance
    function getBalance() internal view safetyLock returns(uint256){
        require(stage == RaffleStage.Open, "Raffle must be Open to see the balance");

        return (address(this).balance);
    }

    //Updating Stages
    function updateStage(RaffleStage _stage) public onlyAdmins safetyLock{
        stage = _stage;
    }

    /* RAFFLE FUNCTIONS */
    /**
    * @dev Create a new raffle with updated fees, prize, and closing time.
    * This function is used by admins to start a new raffle. It can only be called when the current raffle is in the 'RaffleStage.Closed' stage.
    * The function takes four parameters: 'feeToUpdate' for the updated entrance fee, 'newPrize' for the updated prize amount,
    * 'newSoftcap' for the updated softcap, and 'timeToClose' for the time duration until the raffle closes.
    * The function performs several checks to ensure that the raffle is in the correct stage and that the closing time is valid (not equal to 0).
    * If all conditions are met, the function updates the 'ticketCost', 'softcap', 'prize', and 'raffleClosing' variables with the new values.
    * It also increments the 'raffleId' to identify the new raffle.
    * The function then processes any ticket reallocations for the next raffle, updating the 'entryCount' for participants who had tickets reallocated.
    * The 'updateStage' function is called to set the new stage to 'RaffleStage.Open', indicating that the raffle is now open for ticket purchases.
    * The function emits events to signal the start of the new raffle, the updated prize amount, and the updated ticket cost.
    * @param feeToUpdate The updated entrance fee for the raffle.
    * @param newPrize The updated prize for the raffle.
    * @param newSoftcap The updated softcap for the raffle.
    * @param timeToClose The time duration for the raffle to close.
    */
    function updateAndOpenRaffle(uint256 feeToUpdate,
                          uint256 newPrize,
                          uint256 newSoftcap,
                          uint256 timeToClose) onlyAdmins safetyLock public {

        require(stage == RaffleStage.Closed, "Wrong stage. Raffle must be closed."); 
        require (timeToClose != 0, "Closing time must be set!"); 

        lastTimeStamp = block.timestamp;
        ticketCost = feeToUpdate;
        softcap = newSoftcap;
        prize = newPrize;
        raffleClosing = SafeMath.add(lastTimeStamp, timeToClose);
        raffleId++;        

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
    * @dev Allows participants to buy raffle tickets by sending Ether to the contract.
    * This function is available during the RaffleStage.Open period, before the raffle closing time.
    * Participants specify the number of tickets they want to purchase with the 'numberOfTickets' parameter.
    * The function verifies that the raffle is in the correct stage, the closing time has not been reached,
    * and a positive number of tickets is requested. Additionally, the function checks if the correct amount
    * of Ether is sent for the specified number of tickets based on the 'ticketCost'.
    * If all conditions are met, the participant's ticket count is updated in the 'entryCount' mapping, and
    * the total number of entries is increased accordingly. If the participant is a new player, their address
    * is added to the 'players' array. The participant's address is also added 'numberOfTickets' times to the
    * 'playerSelector' array, which is later used for random winner selection.
    * The function emits events to record the new entry and the number of tickets bought by the participant.
    */
    function buyTicket(uint256 numberOfTickets) public payable safetyLock {
        require(stage == RaffleStage.Open, "It's not open yet!");
        require(block.timestamp < raffleClosing, "Check the closing time!");
        require(numberOfTickets > 0);
            
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

    /**
    * @dev Selects the winner of the raffle using Chainlink VRF.
    * The function requests a random number from Chainlink VRF and calculates
    * the winner index based on the random number and the number of players.
    * The address of the player at the calculated index becomes the winner.
    * Only admins can call this function, and it can only be called during the
    * RaffleStage.Calculating period with a sufficient balance in the contract.
    */
    function selectWinner() public safetyLock onlyAdmins {
        require(stage == RaffleStage.Calculating, "Wrong stage. Raffle isnt ready to pick a winner!");
        require(playerSelector.length > 0, "There are no players");

        uint256 randomValue = vrfv2consumer.requestRandomWords();

        uint256 winnerIndex = randomValue % playerSelector.length;

        address winnerAddress = playerSelector[winnerIndex];

        winner = payable(winnerAddress);

        emit RequestedRaffleWinner();
        emit WinnerSelected(winnerIndex, winnerAddress, randomValue);
    }

    /* PAY WINNER FUNCTION */

    /**
    * @dev Pay the raffle winner and close the raffle.
    * This function is called after the raffle winner is determined and the prize amount is set.
    * It transfers the prize amount to the winner's address and emits an event to record the payment.
    * After paying the winner, the raffle is closed by changing the stage to RaffleStage.Closed.
    * The contract balance will then be distributed among the admins using the withdrawBalance() function.
    * If the prize amount is zero, the raffle is considered invalid, and the winner's address is set to address(0).
    */
    function payWinner() public onlyAdmins safetyLock {
        require(stage == RaffleStage.Calculating, "Wrong stage. Raffle isnt ready to pick a winner!");
        require(winner != address(0), "No winner selected");

        uint256 prizeAmount = prize;

        if (prizeAmount > 0) {
            recentWinners[raffleId] = payable(winner);
            (bool success, ) = winner.call{value: prizeAmount}("");
            require(success, "Transfer failed");

            emit WinnerPaid(winner, prizeAmount);

            stage = RaffleStage.Closed;

            withdrawBalance();            
        }
        else {recentWinners[raffleId] = payable(address(0));}
    }

    /* REFUND FUNCTIONS */

    /**
    * @dev Allows participants to request a refund if the current raffle did not meet the conditions and got canceled.
    * This function is only available during the RaffleStage.Canceled period. After requesting the refund here,
    * the function validates the request and sets the refund amount to claim in the claimRefund function by calling
    * calculateRefundAmount. Participants can only request a refund once, and the amount will be set for claiming.
    */
    function requestRefund() public safetyLock{
        require(stage == RaffleStage.Canceled, "Wrong stage. Raffle isnt canceled!");

        uint256 refundAmount = calculateRefundAmount(msg.sender);

        if (refundRequests[msg.sender].refundAmount != 0) {revert RefundAlreadyRequested();}

        if (refundRequests[msg.sender].claimed) {revert RefundAlreadyClaimed();}
        
        if (refundAmount == 0) {revert NoRefundAvailable();}

        refundRequests[msg.sender].refundAmount = refundAmount;
    }

    // Search for the total spend with Raffle Tickets
    function calculateRefundAmount(address participant) internal view safetyLock returns (uint256) {
        require(stage == RaffleStage.Canceled, "Wrong stage. Raffle isnt canceled!");

        uint256 totalAmountSpent = 0;

        for (uint256 i = 0; i < players.length; i++) {
            address player = players[i];
            uint256 numberOfTickets = entryCount[player];
            if (player == participant && numberOfTickets > 0) {totalAmountSpent = totalAmountSpent.add(numberOfTickets.mul(ticketCost));}
        }
        return totalAmountSpent;
    }

    /**
    * @dev Allows a participant to claim the refund amount after requesting it in requestRefund() and having the amount calculated by calculateRefundAmount().
    * Once the participant makes a refund request and the amount is calculated, they can claim the refund here. 
    * The refund will be transferred to the participant's address.
    * Participants can only claim the refund once, and the amount will be set to zero after the refund is processed.
    */
    function claimRefund() public safetyLock{
        require(stage == RaffleStage.Canceled, "Wrong stage. Raffle isnt canceled!");

        if (refundRequests[msg.sender].refundAmount == 0) {revert NoRefundAvailable();}

        if (refundRequests[msg.sender].claimed) {revert RefundAlreadyClaimed();}

        uint256 amountToRefund = refundRequests[msg.sender].refundAmount;
        refundRequests[msg.sender].refundAmount = 0;
        refundRequests[msg.sender].claimed = true;

        payable(msg.sender).transfer(amountToRefund);

        emit RefundClaimed(msg.sender, amountToRefund);
    }

    /**
    * @dev Pay back participants who have not claimed their refunds.
    * This function iterates through all players who have pending refund amounts but have not claimed them,
    * and pays each one back. It is not recommended to use this function when too many participants have
    * not requested or claimed their refunds, as it may consume a significant amount of gas.
    * If for some reason the Administration decides not to proceed with other Raffles,
    * this function can be used to refund participants with minimal gas cost.
    */
    function refundAllForgottenParticipants() public onlyAdmins safetyLock {
        require(stage == RaffleStage.Canceled, "Wrong stage. Raffle isnt canceled!");

        for (uint256 i = 0; i < players.length; i++) {
            address participant = players[i];

            uint256 amountToRefund = refundRequests[participant].refundAmount;

            if (amountToRefund > 0) {
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
    * This function is called when a new raffle is opened, and it reallocates tickets from the previous raffle
    * to the new one for participants who did not request a refund. The reallocated players are added back to the
    * playerSelector array, ensuring they can participate in the new raffle. The function iterates through the players
    * and checks for refund requests. For each participant who did not request a refund, it adds their tickets to the
    * entryCount for the new raffle and emits an event to notify the participant about the ticket reallocation.
    * 
    * Note: The function assumes that the player array is already reset (cleared) when a new raffle starts,
    * so it doesn't handle the player array reset here.
    * 
    * @param nextRaffleId The ID of the next raffle to reallocate tickets.
    */
    function reallocateTicketsToNextRaffle(uint256 nextRaffleId) public onlyAdmins safetyLock {
    require(stage == RaffleStage.Canceled, "Wrong stage. Raffle isnt canceled!");

    address[] memory reallocatedPlayers = new address[](players.length);

    uint256 newIndex = 0;
    for (uint256 i = 0; i < players.length; i++) {
        address participant = players[i];

        if (refundRequests[participant].refundAmount > 0 && !refundRequests[participant].claimed) {
            
            uint256 ticketCount = entryCount[participant];
            uint256 refundAmount = refundRequests[participant].refundAmount;
            uint256 reallocationIndex = ticketReallocationCounter;
            ticketReallocationInfo[reallocationIndex] = TicketReallocation(participant, ticketCount, refundAmount, nextRaffleId);
            ticketReallocationCounter++;

            emit TicketsReallocated(participant, ticketCount, refundAmount, nextRaffleId);
        } else {
            reallocatedPlayers[newIndex] = participant;
            newIndex++;
        }
    }

    // Resize the reallocatedPlayers array to the correct size (number of reallocated players)
    address[] memory finalReallocatedPlayers = new address[](newIndex);
    for (uint256 i = 0; i < newIndex; i++) {
        finalReallocatedPlayers[i] = reallocatedPlayers[i];
    }

    // Update the players array with the reallocated players
    players = finalReallocatedPlayers;
}


    /**
    * @dev Reset the contract to its initial state.
    * This function will clear all mappings and arrays that received any values during the current Raffle period,
    * ensuring no interference with the next Raffle. Before the cleaning, the function checks if the contract has
    * any remaining balance and transfers it to the contract owner if applicable. Only the contract owner can call
    * this function.
    */
    function resetContract() public onlyOwner safetyLock {
        delete playerSelector;
        delete players;
        delete adminAddresses;
        totalEntries = 0;
        stage = RaffleStage.Closed;

        emit ContractReseted();
    }

    /* MODIFIERS */
    //onlyOwner
    modifier onlyOwner() {
       require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    //onlyAdmins
    modifier onlyAdmins {
        require(s_administration[msg.sender].isAdmin, "Only admin and owner can call this function!");
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

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract RaffleVRFv2Consumer is VRFConsumerBaseV2 {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests;
    VRFCoordinatorV2Interface COORDINATOR;

    //State variable
    address private owner;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    bytes32 keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;

    constructor()
        VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed
        );
        s_subscriptionId = 5413;
        owner = msg.sender;
    }

    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
 
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

    modifier onlyOwner() {
       require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}