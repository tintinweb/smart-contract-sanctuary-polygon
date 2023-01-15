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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

// import IERC20 from openzepplin
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import chainlink VRF
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
// import chainlink interface for vrf coordinator v2
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

interface ILotto {
    function deposit(address token, uint256 amount) external;
}

interface IBurnable {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

interface IOwnable {
    function getOwner() external view returns (address);
}

contract Lotto is ILotto, VRFConsumerBaseV2 {
    // Lotto Constants
    uint256 public constant day = 28800;
    uint256 public constant week = day * 7;
    uint256 public constant month = day * 30;
    uint32 public constant MONTHLY_WINNERS = 1;
    uint32 public constant WEEKLY_WINNERS = 1;
    uint32 public constant DAILY_WINNERS = 1;

    // Adventure Tip Contract
    address public immutable AdventureTip;

    // minimum Adeventure Tokens register to get one ticket
    uint256 public AT_Per_Ticket = 1 * 10**18;

    // Ticket Ranges
    struct TicketRange {
        uint256 lower;
        uint256 upper;
        address user;
    }
    // Ticket Range ID => TicketRange
    mapping(uint256 => TicketRange) public dailyTicketRanges;
    uint256 public currentDailyTicketRangeID;

    // Ticket Range ID => TicketRange
    mapping(uint256 => TicketRange) public weeklyTicketRanges;
    uint256 public currentWeeklyTicketRangeID;

    // Ticket Range ID => TicketRange
    mapping(uint256 => TicketRange) public monthlyTicketRanges;
    uint256 public currentMonthlyTicketRangeID;

    // number of tickets currently issued
    uint256 public currentDailyTicketID;
    uint256 public currentWeeklyTicketID;
    uint256 public currentMonthlyTicketID;

    // User -> Tokens Won In Lotto
    mapping(address => uint256) public userWinnings;

    // Lotto User Data
    address[] public monthlyWinners;
    address[] public weeklyWinners;
    address[] public dailyWinners;

    // Block Times
    uint256 public lastDay; // time block of the last recorded day
    uint256 public lastWeek; // time block of the last recorded week
    uint256 public lastMonth; // time block of the last recorded month

    // percent of balance that rolls over to next lotto cycle
    uint256 public rollOverPercentage = 0; // 10 = 10%

    // token reward allocations
    uint256 public dailyWinnersPercent = 40;
    uint256 public weeklyWinnersPercent = 40;
    uint256 public monthlyWinnersPercent = 20;
    uint256 public percentDenominator = 100;

    // Gas For Lottery Trigger
    uint32 public dailyGas = 200_000;
    uint32 public weeklyGas = 200_000;
    uint32 public monthlyGas = 200_000;

    // lotto reward token
    address public rewardToken;
    uint256 public dailyWinnersPot;
    uint256 public weeklyWinnersPot;
    uint256 public monthlyWinnersPot;

    // Governance
    modifier onlyOwner() {
        require(
            msg.sender == IOwnable(AdventureTip).getOwner(),
            "Only Adventure Tip Owner Can Call"
        );
        _;
    }

    ////////////////////////////////////////////////
    ///////////   CHAINLINK VARIABLES    ///////////
    ////////////////////////////////////////////////

    // VRF Coordinator
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // testnet BNB coordinator
    address private immutable vrfCoordinator; // = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    bytes32 private immutable keyHash; // = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;

    // chainlink request IDs
    uint256 private newDayRequestId;
    uint256 private newWeekRequestId;
    uint256 private newMonthRequestId;

    constructor(
        address AdventureTip_,
        address rewardToken_,
        uint64 subscriptionId,
        address vrfCoordinator_,
        bytes32 keyHash_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        // setup chainlink
        keyHash = keyHash_;
        vrfCoordinator = vrfCoordinator_;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
        s_subscriptionId = subscriptionId;

        // set state
        AdventureTip = AdventureTip_;
        rewardToken = rewardToken_;
    }

    ////////////////////////////////////////////////
    ///////////   RESTRICTED FUNCTIONS   ///////////
    ////////////////////////////////////////////////

    /**
        Sets Gas Limits for VRF Callback
     */
    function setGasLimits(
        uint32 dailyGas_,
        uint32 weeklyGas_,
        uint32 monthlyGas_
    ) external onlyOwner {
        dailyGas = dailyGas_;
        weeklyGas = weeklyGas_;
        monthlyGas = monthlyGas_;
    }

    /**
        Sets Subscription ID for VRF Callback
     */
    function setSubscriptionId(uint64 subscriptionId_) external onlyOwner {
        s_subscriptionId = subscriptionId_;
    }

    /**
        Starts The Timer For Days And Months For Lotto Enrollment
     */
    function startTime() external onlyOwner {
        require(
            lastDay == 0 && lastWeek == 0 && lastMonth == 0,
            "Already Started"
        );

        lastDay = block.number;
        lastWeek = block.number;
        lastMonth = block.number;
    }

    /**
        Resets The Day And Month For Lotto Winners To The Current Block Number
     */
    function hardResetLottoTimers() external onlyOwner {
        require(
            lastDay > 0 && lastWeek > 0 && lastMonth > 0,
            "Call startTime()"
        );

        lastDay = block.number;
        lastWeek = block.number;
        lastMonth = block.number;
    }

    /**
        Forcefully Registers The Current Block Number As A New Day
        Runs The Lotto, Delivering Rewards To Daily Winners As Intended
        Should Be Used VERY Carefully
        This is a dangerous function, as it changes the timing and frequency of lotto rewards
     */
    function forceNewDay() external onlyOwner {
        _newDay();
    }

    /**
        Forcefully Registers The Current Block Number As A New Week
        Runs The Lotto, Delivering Rewards To Daily Winners As Intended
        Should Be Used VERY Carefully
        This is a dangerous function, as it changes the timing and frequency of lotto rewards
     */
    function forceNewWeek() external onlyOwner {
        _newWeek();
    }

    /**
        Forcefully Registers The Current Block Number As A New Month
        Runs The Lotto, Delivering Rewards To Monthly Winners As Intended
        Should Be Used VERY Carefully
        This is a dangerous function, as it changes the timing and frequency of lotto rewards
     */
    function forceNewMonth() external onlyOwner {
        _newMonth();
    }

    /**
        Forcefully Registers The Current Block Number As A New Day, Week, And Month
        Runs The Lotto, Delivering Rewards To Daily And Monthly Winners As Intended
        Should Be Used VERY Carefully
        This is a dangerous function, as it changes the timing and frequency of lotto rewards
     */
    function forceNewDayWeekAndMonth() external onlyOwner {
        _newDay();
        _newWeek();
        _newMonth();
    }

    /**
        Gifts Tickets For External User
        Should be called carefully and with open transparency to community
        Allows team to host special events and do games to win tickets
        @param user - user to receive the tickets
        @param nTickets - number of tickets to gift to `user`
        @param lottoType - 0 = daily, 1 = weekly, 2 = monthly
     */
    function giftTickets(
        address user,
        uint256 nTickets,
        uint256 lottoType
    ) external onlyOwner {
        require(lottoType < 3, "Invalid Lotto Type");
        require(nTickets > 0, "Must Gift At Least 1 Ticket");
        if (lottoType == 0) {
            _addDailyTickets(user, nTickets);
        } else if (lottoType == 1) {
            _addWeeklyTickets(user, nTickets);
        } else if (lottoType == 2) {
            _addMonthlyTickets(user, nTickets);
        }
    }

    /**
        Resets The Token Pot Percentages Based On Current Balance Within Contract
        Useful For When Tokens Are Withdrawn Or Sent In Without Calling `deposit()`
     */
    function hardResetRewardTokenPot() external onlyOwner {
        // fetch token balance
        uint256 bal = IERC20(rewardToken).balanceOf(address(this));

        // divvy up balance
        uint256 dwp = (bal * dailyWinnersPercent) / percentDenominator;
        uint256 wwp = (bal * weeklyWinnersPercent) / percentDenominator;
        uint256 mwp = bal - (dwp + wwp);

        // set pot size to be reset balances
        dailyWinnersPot = dwp;
        weeklyWinnersPot = wwp;
        monthlyWinnersPot = mwp;
    }

    /**
        Sets The Percentages For Reward Token Pool Distributions
     */
    function setRewardPotPercentages(
        uint256 daily_,
        uint256 weekly_,
        uint256 monthly_
    ) external onlyOwner {
        dailyWinnersPercent = daily_;
        weeklyWinnersPercent = weekly_;
        monthlyWinnersPercent = monthly_;
        percentDenominator = daily_ + weekly_ + monthly_;
    }

    /**
        Withdraws BNB That Is Stuck In This Contract
        Contract does not have receive function, so bnb can only enter
        via an external selfdestruct() function call
     */
    function withdrawBNB() external onlyOwner {
        (bool s, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    /**
        Withdraws Tokens Held Within Contract
            Dangerous If Withdrawing RewardToken
            If A Reward Token Is Withdrawn, Immediately Call `hardResetRewardTokenPot()`
     */
    function withdrawTokens(IERC20 token_) external onlyOwner {
        token_.transfer(msg.sender, token_.balanceOf(address(this)));
    }

    /**
        Sets The Roll Over Percentage For Lotto Games
        A `newPercent` value of 10 will roll over 10% of all remaining funds to the next lotto
        @param newPercent - new percentage of winnings to roll over to next lotto
     */
    function setRollOverPercentage(uint256 newPercent) external onlyOwner {
        require(newPercent >= 0 && newPercent < 100, "Percent Out Of Bounds");
        rollOverPercentage = newPercent;
    }

    /**
        Sets Rate For How Many Adventure Tips Should Be Deposited To Register 1 Ticket
        @param newAtPerTicketValue - number of ATs per ticket registered, cannot be zero
     */
    function setAtPerTicket(uint256 newAtPerTicketValue) external onlyOwner {
        require(newAtPerTicketValue > 0, "Cannot Be Zero");

        AT_Per_Ticket = newAtPerTicketValue;
    }

    ////////////////////////////////////////////////
    ///////////    PUBLIC FUNCTIONS      ///////////
    ////////////////////////////////////////////////

    /**
        Deposits `amount` of `token` into contract
        If `token` is a registered rewardToken, it will add it
        to the lotto pools as determined by their percentages
        NOTE: Must Have Prior Approval of token for address(this) before calling
        @param token - the token to deposit
        @param amount - amount of `token` to deposit
     */
    function deposit(address token, uint256 amount) external override {
        uint256 received = _transferIn(IERC20(token), amount);

        if (token == rewardToken) {
            uint256 dwp = (received * dailyWinnersPercent) / percentDenominator;
            uint256 wwp = (received * weeklyWinnersPercent) /
                percentDenominator;
            uint256 mwp = received - (dwp + wwp);

            dailyWinnersPot += dwp;
            weeklyWinnersPot += wwp;
            monthlyWinnersPot += mwp;
        }
    }

    /**
        Burns Adventure Tips For Tickets
        NOTE: Must Have Prior Approval of Adventure Tips for address(this) before calling
        @param amount - number of Adventure Tips to burn for tickets
     */
    function enterDailyPool(uint256 amount) external {
        // burn the Adventure Tips from the user
        IBurnable(AdventureTip).burnFrom(msg.sender, amount);
        // Add Tickets For Sender
        _addDailyTickets(msg.sender, AT_Per_Ticket * amount);
    }

    /**
        Burns Adventure Tips For Tickets
        NOTE: Must Have Prior Approval of Adventure Tips for address(this) before calling
        @param amount - number of Adventure Tips to burn for tickets
     */
    function enterWeeklyPool(uint256 amount) external {
        // burn the Adventure Tips from the user
        IBurnable(AdventureTip).burnFrom(msg.sender, amount);
        // Add Tickets For Sender
        _addWeeklyTickets(msg.sender, AT_Per_Ticket * amount);
    }

    /**
        Burns Adventure Tips For Tickets
        NOTE: Must Have Prior Approval of Adventure Tips for address(this) before calling
        @param amount - number of Adventure Tips to burn for tickets
     */
    function enterMonthlyPool(uint256 amount) external {
        // burn the Adventure Tips from the user
        IBurnable(AdventureTip).burnFrom(msg.sender, amount);
        // Add Tickets For Sender
        _addMonthlyTickets(msg.sender, AT_Per_Ticket * amount);
    }

    /**
        Public Function To Trigger Daily And Monthly Lotto Results
        If The Correct Amount Of Time Has Passed
     */
    function newDay() public {
        if (isNewDay()) {
            _newDay();
        }

        if (isNewWeek()) {
            _newWeek();
        }

        if (isNewMonth()) {
            _newMonth();
        }
    }

    ////////////////////////////////////////////////
    ///////////   INTERNAL FUNCTIONS     ///////////
    ////////////////////////////////////////////////

    /**
        Registers A New Day
        Changes The Day Timer
        Distributes Daily Winnings And Largest Daily Deposit Winnings
     */
    function _newDay() internal {
        // reset day timer
        lastDay = block.number;

        // get random number and send rewards when callback is executed
        // the callback is called "fulfillRandomWords"
        // this will revert if VRF subscription is not set and funded.
        newDayRequestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            3, // number of block confirmations before returning random value
            dailyGas, // callback gas limit is dependent num of random values & gas used in callback
            DAILY_WINNERS // the number of random results to return
        );
    }

    /**
        Registers A New Week
        Changes The Week Timer
        Distributes Weekly Winnings Winnings
     */
    function _newWeek() internal {
        // reset day timer
        lastWeek = block.number;

        // get random number and send rewards when callback is executed
        // the callback is called "fulfillRandomWords"
        // this will revert if VRF subscription is not set and funded.
        newWeekRequestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            3, // number of block confirmations before returning random value
            weeklyGas, // callback gas limit is dependent num of random values & gas used in callback
            WEEKLY_WINNERS // the number of random results to return
        );
    }

    /**
        Registers A New Month, Changing The Timer And Distributing Monthly Lotto Winnings
     */
    function _newMonth() internal {
        // reset month timer
        lastMonth = block.number;

        // get random number and send rewards when callback is executed
        // the callback is called "fulfillRandomWords"
        // this will revert if VRF subscription is not set and funded.
        newMonthRequestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            3, // number of block confirmations before returning random value
            monthlyGas, // callback gas limit is dependent num of random values & gas used in callback
            MONTHLY_WINNERS // the number of random results to reeturn
        );
    }

    /**
        Chainlink's callback to provide us with randomness
     */
    function fulfillRandomWords(
        uint256 requestId, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        if (requestId == newDayRequestId) {
            _sendDailyRewards(randomWords);
            // reset ticket IDs back to 0
            delete currentDailyTicketID;
            delete currentDailyTicketRangeID;
        } else if (requestId == newWeekRequestId) {
            _sendWeeklyRewards(randomWords);
            // reset ticket IDs back to 0
            delete currentWeeklyTicketID;
            delete currentWeeklyTicketRangeID;
        } else if (requestId == newMonthRequestId) {
            _sendMonthlyRewards(randomWords);
            // reset ticket IDs back to 0
            delete currentMonthlyTicketID;
            delete currentMonthlyTicketRangeID;
        }
    }

    function _addDailyTickets(address user, uint256 nTickets) internal {
        // use upper bound of old range as lower bound of new range
        uint256 lower = currentDailyTicketRangeID == 0
            ? 0
            : dailyTicketRanges[currentDailyTicketRangeID - 1].upper;

        // set state for new range
        dailyTicketRanges[currentDailyTicketRangeID].lower = lower;
        dailyTicketRanges[currentDailyTicketRangeID].upper = lower + nTickets;
        dailyTicketRanges[currentDailyTicketRangeID].user = user;

        // increment current Ticket ID
        currentDailyTicketID += nTickets;

        // increment ticket range
        currentDailyTicketRangeID++;
    }

    function _addWeeklyTickets(address user, uint256 nTickets) internal {
        // use upper bound of old range as lower bound of new range
        uint256 lower = currentWeeklyTicketRangeID == 0
            ? 0
            : weeklyTicketRanges[currentWeeklyTicketRangeID - 1].upper;

        // set state for new range
        weeklyTicketRanges[currentDailyTicketRangeID].lower = lower;
        weeklyTicketRanges[currentDailyTicketRangeID].upper = lower + nTickets;
        weeklyTicketRanges[currentDailyTicketRangeID].user = user;

        // increment current Ticket ID
        currentWeeklyTicketID += nTickets;

        // increment ticket range
        currentWeeklyTicketRangeID++;
    }

    function _addMonthlyTickets(address user, uint256 nTickets) internal {
        // use upper bound of old range as lower bound of new range
        uint256 lower = currentMonthlyTicketRangeID == 0
            ? 0
            : monthlyTicketRanges[currentMonthlyTicketRangeID - 1].upper;

        // set state for new range
        monthlyTicketRanges[currentDailyTicketRangeID].lower = lower;
        monthlyTicketRanges[currentDailyTicketRangeID].upper = lower + nTickets;
        monthlyTicketRanges[currentDailyTicketRangeID].user = user;

        // increment current Ticket ID
        currentMonthlyTicketID += nTickets;

        // increment ticket range
        currentMonthlyTicketRangeID++;
    }

    /**
        Fetches the owner of a ticket by the ticket ID.
        @param id The ID of the ticket to fetch the owner of.
        @param lottoType The type of lotto to fetch the ticket owner of. 0 = daily, 1 = weekly, 2 = monthly.
     */
    function _fetchTicketOwner(uint256 id, uint256 lottoType)
        internal
        view
        returns (address user)
    {
        if (lottoType == 0) {
            for (uint256 i = 0; i < currentDailyTicketRangeID; ) {
                if (
                    dailyTicketRanges[i].lower <= id &&
                    dailyTicketRanges[i].upper > id
                ) {
                    return dailyTicketRanges[i].user;
                }

                unchecked {
                    ++i;
                }
            }
            return address(0);
        } else if (lottoType == 1) {
            for (uint256 i = 0; i < currentWeeklyTicketRangeID; ) {
                if (
                    weeklyTicketRanges[i].lower <= id &&
                    weeklyTicketRanges[i].upper > id
                ) {
                    return weeklyTicketRanges[i].user;
                }

                unchecked {
                    ++i;
                }
            }
            return address(0);
        } else if (lottoType == 2) {
            for (uint256 i = 0; i < currentMonthlyTicketRangeID; ) {
                if (
                    monthlyTicketRanges[i].lower <= id &&
                    monthlyTicketRanges[i].upper > id
                ) {
                    return monthlyTicketRanges[i].user;
                }

                unchecked {
                    ++i;
                }
            }
            return address(0);
        }
    }

    /**
        Processes Daily Reward Lotto
     */
    function _sendDailyRewards(uint256[] memory random) internal {
        if (currentDailyTicketID == 0 || currentDailyTicketRangeID == 0) {
            return;
        }

        // load daily winners number into memory for gas optimization
        uint256 numDailyWinners = uint256(DAILY_WINNERS);

        // create winner array
        address[] memory addr = new address[](numDailyWinners);
        for (uint256 i = 0; i < numDailyWinners; ) {
            address winner = _fetchTicketOwner(
                random[i] % currentDailyTicketID,
                0
            );
            addr[i] = winner;
            unchecked {
                ++i;
            }
        }

        // calculate reward pot size
        uint256 rewardPot = (dailyWinnersPot * (100 - rollOverPercentage)) /
            100;

        // send reward pot to winners
        if (rewardPot > 0) {
            // decrement rewards from the dailyWinnersPot tracker
            dailyWinnersPot -= rewardPot;

            // distribute rewards to winning addresses
            _distributeRewards(addr, rewardPot);
        }

        // clear data
        delete random;
        delete addr;
    }

    /**
        Processes Weekly Reward Lotto
     */
    function _sendWeeklyRewards(uint256[] memory random) internal {
        if (currentWeeklyTicketID == 0 || currentWeeklyTicketRangeID == 0) {
            return;
        }

        // load weekly winners number into memory for gas optimization
        uint256 numWeeklyWinners = uint256(WEEKLY_WINNERS);

        // create winner array
        address[] memory addr = new address[](numWeeklyWinners);
        for (uint256 i = 0; i < numWeeklyWinners; ) {
            address winner = _fetchTicketOwner(
                random[i] % currentDailyTicketID,
                1
            );
            addr[i] = winner;
            unchecked {
                ++i;
            }
        }

        // calculate reward pot size
        uint256 rewardPot = (weeklyWinnersPot * (100 - rollOverPercentage)) /
            100;

        // send reward pot to winners
        if (rewardPot > 0) {
            // decrement rewards from the dailyDepositPot tracker
            weeklyWinnersPot -= rewardPot;

            // distribute rewards to winning addresses
            _distributeRewards(addr, rewardPot);
        }

        // clear data
        delete random;
        delete addr;
    }

    /**
        Processes Monthly Reward Lotto
     */
    function _sendMonthlyRewards(uint256[] memory random) internal {
        if (currentMonthlyTicketID == 0 || currentMonthlyTicketRangeID == 0) {
            return;
        }
        // load monthly winners into memory for gas optimization
        uint256 numMonthlyWinners = uint256(MONTHLY_WINNERS);

        // create winner array
        address[] memory addr = new address[](numMonthlyWinners);
        for (uint256 i = 0; i < numMonthlyWinners; ) {
            address winner = _fetchTicketOwner(
                random[i] % currentDailyTicketID,
                2
            );
            addr[i] = winner;
            unchecked {
                ++i;
            }
        }

        // decrement pot
        uint256 rewardPot = (monthlyWinnersPot * (100 - rollOverPercentage)) /
            100;

        // send reward to winner
        if (rewardPot > 0) {
            // decrement rewards from the monthlyWinnersPot tracker
            monthlyWinnersPot -= rewardPot;

            // distribute rewards to winning addresses
            _distributeRewards(addr, rewardPot);
        }

        // clear data
        delete random;
        delete addr;
    }

    /**
        Distributes `rewardPot` amongst `recipients` in the reward token
     */
    function _distributeRewards(address[] memory recipients, uint256 rewardPot)
        internal
    {
        // length
        uint256 length = recipients.length;

        // calculate rewards per user -- avoiding round off error
        uint256 r0 = rewardPot / length;
        uint256 r1 = rewardPot - (r0 * (length - 1));

        // transfer winnings to users
        for (uint256 j = 0; j < length; ) {
            if (recipients[j] != address(0)) {
                uint256 amt = j == (length - 1) ? r1 : r0;
                _sendToken(recipients[j], amt);
            }
            unchecked {
                ++j;
            }
        }
    }

    /**
        Transfers in `amount` of `token` to address(this)
        NOTE: Must have prior approval for `token` for address(this)
     */
    function _transferIn(IERC20 token, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 before = token.balanceOf(address(this));
        bool s = token.transferFrom(msg.sender, address(this), amount);
        uint256 received = token.balanceOf(address(this)) - before;
        require(s && received > 0 && received <= amount, "Error TransferFrom");
        return received;
    }

    /**
        Sends `amount` of `token` to `to` 
     */
    function _sendToken(address to, uint256 amount) internal {
        if (to == address(0)) {
            return;
        }
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        if (amount > balance) {
            amount = balance;
        }
        if (amount == 0) {
            return;
        }
        // update user winnings
        userWinnings[to] += amount;
        // send reward
        require(
            IERC20(rewardToken).transfer(to, amount),
            "Failure On Token Transfer"
        );
    }

    ////////////////////////////////////////////////
    ///////////      READ FUNCTIONS      ///////////
    ////////////////////////////////////////////////

    /**
        Returns True If It Is A New Day And _newDay() Can Be Called, False Otherwise
     */
    function isNewDay() public view returns (bool) {
        return (block.number - lastDay) >= day;
    }

    /**
        Returns True If It Is A New Week And _newWeek() Can Be Called, False Otherwise
     */
    function isNewWeek() public view returns (bool) {
        return (block.number - lastWeek) >= week;
    }

    /**
        Returns True If It Is A New Month And _newMonth() Can Be Called, False Otherwise
     */
    function isNewMonth() public view returns (bool) {
        return (block.number - lastMonth) >= month;
    }

    function timeLeftUntilNewDay() public view returns (uint256) {
        return isNewDay() ? 0 : day - (block.number - lastDay);
    }

    function timeLeftUntilNewWeek() public view returns (uint256) {
        return isNewWeek() ? 0 : week - (block.number - lastWeek);
    }

    function timeLeftUntilNewMonth() public view returns (uint256) {
        return isNewMonth() ? 0 : month - (block.number - lastMonth);
    }

    /**
        Returns The Number Of Tickets Associated With `user`
        @param user - user whose ticket balance is being returned
        @param lottoType - 0 = daily, 1 = weekly, 2 = monthly
     */
    function balanceOf(address user, uint256 lottoType)
        public
        view
        returns (uint256 nTickets)
    {
        if (lottoType == 0) {
            uint256 id = currentDailyTicketRangeID;
            for (uint256 i = 0; i < id; ) {
                if (dailyTicketRanges[i].user == user) {
                    nTickets += (dailyTicketRanges[i].upper -
                        dailyTicketRanges[i].lower);
                }
                unchecked {
                    ++i;
                }
            }
        } else if (lottoType == 1) {
            uint256 id = currentWeeklyTicketRangeID;
            for (uint256 i = 0; i < id; ) {
                if (weeklyTicketRanges[i].user == user) {
                    nTickets += (weeklyTicketRanges[i].upper -
                        weeklyTicketRanges[i].lower);
                }
                unchecked {
                    ++i;
                }
            }
        } else if (lottoType == 2) {
            uint256 id = currentMonthlyTicketRangeID;
            for (uint256 i = 0; i < id; ) {
                if (monthlyTicketRanges[i].user == user) {
                    nTickets += (monthlyTicketRanges[i].upper -
                        monthlyTicketRanges[i].lower);
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
        Returns The Ticket Balance Of `user` As Well As The Total Tickets In This Round
        @param user - user whose ticket balance is being returned
     */
    function chanceToWinDaily(address user)
        public
        view
        returns (uint256, uint256)
    {
        return (balanceOf(user, 0), currentDailyTicketID);
    }

    /**
        Returns The Ticket Balance Of `user` As Well As The Total Tickets In This Round
        @param user - user whose ticket balance is being returned
     */
    function chanceToWinWeekly(address user)
        public
        view
        returns (uint256, uint256)
    {
        return (balanceOf(user, 1), currentWeeklyTicketID);
    }

    /**
        Returns The Ticket Balance Of `user` As Well As The Total Tickets In This Round
        @param user - user whose ticket balance is being returned
     */
    function chanceToWinMonthly(address user)
        public
        view
        returns (uint256, uint256)
    {
        return (balanceOf(user, 2), currentMonthlyTicketID);
    }
}