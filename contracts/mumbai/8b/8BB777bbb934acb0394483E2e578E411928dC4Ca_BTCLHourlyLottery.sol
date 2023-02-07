// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { AutomationCompatible } from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import { AutomatedRandomness } from "./extended/AutomatedRandomness.sol";
import { BTCLCore } from "./libraries/BTCLCore.sol";

contract BTCLHourlyLottery is AutomationCompatible, AutomatedRandomness, ReentrancyGuard {
    /* ============ Global Variables ============ */
    using SafeERC20 for IERC20;

    // Mapping to store the details of each round
    mapping(uint => BTCLCore.Round) public rounds;

    // Current round number
    uint256 public round;

    // uint256 public ticketPrice = 5 ether;   // 5 MATIC x 1 ticket price
    // uint256 public ticketFee   = 0.5 ether; // 0.5 MATIC ticket fee
    uint256 public ticketPrice = 0.005 ether;  // 0.005 MATIC x 1 ticket price
    uint256 public ticketFee   = 0.0005 ether; // 0.0005 MATIC ticket fee
    uint256 public minPlayers  = 10;           // min 10 tickets per round
    uint256 public maxPlayers  = 100;          // max 100 ticket per round
    uint256 public minutesUntilDraw = 60;      // 1 hour

    /**
     * @dev Constructor for the BTCL Daily Lottery contract
     * @param _coordinatorAddress address of the VRF coordinator contract
     * @param _linkToken address of the Link token contract
     * @param _subscriptionId unique subscription ID for VRF service
     * @param _callbackGasLimit gas limit for the VRF callback
     * @param _requestConfirmations number of confirmations required for VRF requests
     * @param _keyHash Keccak256 hash of the VRF private key
     */
    constructor(
        address _coordinatorAddress,
        address _linkToken,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        bytes32 _keyHash
    )
    AutomatedRandomness(
        _coordinatorAddress,
        _linkToken,
        _subscriptionId,
        _callbackGasLimit,
        _requestConfirmations,
        _keyHash
    ) {
        // Initialize the round number to 1
        round = 1;
        // Set the status of the first round to open
        rounds[round].status.roundStatus = BTCLCore.Status.Open;
        // Set the start date of the first round
        rounds[round].status.startDate = block.timestamp;
        // Set the end date of the first round
        rounds[round].status.endDate =  BTCLCore.addMinutes(block.timestamp, minutesUntilDraw);
    }

    /* ============ External Functions ============ */
    /**
     * @dev Function that allows players to purchase 1 ticket per player
     * Min 10 Players
     * Max 100 Players
     * Max 500$ Prize Game split into 10 dynamic rewards from the pot
     * Max 100 players or min 5 players in 5 minutes and there are atleast 10 unique tickets
     * For every 10 unique players there are different number of rewards
     * Only 10% of the players are rewarded with different tier levels
     * Max 1 lottery ticket per address
     * Ticket Price:  5 MATIC
     * Ticket Fee:  0.5 MATIC
     * Total Price: 5.5 MATIC
     */
    function buyTicket() public payable {
        // Check if the lottery is paused and that there is a new round, if yes, revert the transaction
        if(paused == true && rounds[round].status.totalBets == 0) revert BTCLCore.LOTTERY_PAUSED();

        // Check if the round is open, if not, revert the transaction
        if(rounds[round].status.roundStatus != BTCLCore.Status.Open) revert BTCLCore.TRANSFER_FAILED();

        // Check if the MATIC provided is enough and not rounded
        if((msg.value != (ticketPrice + ticketFee))) revert BTCLCore.TRANSFER_FAILED();

        // Check if already bought a ticket in the current round
        if(rounds[round].contributed[msg.sender] > 0) revert BTCLCore.TRANSFER_FAILED();

        // Check if the round is full to revert the transaction
        if(rounds[round].status.totalBets == maxPlayers) {
            if(rounds[round + 1].contributed[msg.sender] > 0) revert BTCLCore.TRANSFER_FAILED();
            purchaseTickets(round + 1);
            return;
        }

        purchaseTickets(round);

    }

    function purchaseTickets(uint roundNr) private {
        // Set Contribution amount
        rounds[roundNr].contributed[msg.sender] = rounds[roundNr].contributed[msg.sender] + msg.value;

        // get next bet id and current last ticket index
        uint256 nextBet = rounds[roundNr].status.totalBets + 1;
        uint256 lastBet = getLastIndex(roundNr, rounds[roundNr].status.totalBets);

        // sets the purchaser address and ticket amount for the next bet
        setPurchaser(nextBet, msg.sender);
        setLastIndex(nextBet, lastBet + 1);

        // increment the total bets and total tickets of the round
        rounds[roundNr].status.totalBets = nextBet;
        rounds[roundNr].status.totalTickets = rounds[roundNr].status.totalTickets + (msg.value - ticketFee);

        // emit event to log the purchase
        emit BTCLCore.TicketsPurchased(roundNr, msg.sender, msg.value);
    }

    /**
     * @dev Returns true if and only if at least UPKEEP_INTERVAL seconds have elapsed since the last upkeep or since construction of the contract.
     * @dev param checkData the checkData which is used to determine the type of upkeep.
     * @return upkeepNeeded true if and only if at least UPKEEP_INTERVAL seconds have elapsed since the last upkeep or since construction of the contract.
     * @return performData the data that needs to be performed based on checkData type.
     */
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = BTCLCore.checkUpkeepVRF(rounds[round].status.roundStatus, rounds[round].status.endDate, minutesUntilDraw,rounds[round].status.requestId, rounds[round].status.totalBets, maxPlayers, minPlayers);
        performData = abi.encode(round);
    }

    /**
     * @notice Requests randomness from the VRF coordinator 10 seconds before the actual draw
     */
    function performUpkeep(bytes calldata performData) external nonReentrant override {
        // Check if the function is being called at the correct time
        bool reqRandomness = BTCLCore.checkUpkeepVRF(rounds[round].status.roundStatus, rounds[round].status.endDate, minutesUntilDraw, rounds[round].status.requestId, rounds[round].status.totalBets, maxPlayers, minPlayers);

        // Decode the performData to retrieve the round number, winningBetID, and userAddress
        (uint256 _round) = abi.decode(performData, (uint256));

        // Check if the function is being called with the correct parameters
        if(round != _round) revert BTCLCore.UPKEEP_FAILED();
        if(rounds[round].status.roundStatus != BTCLCore.Status.Open) revert BTCLCore.UPKEEP_FAILED();

        // Check if we need to request randomness
        if (reqRandomness){
            rounds[round].status.roundStatus = BTCLCore.Status.Drawing;
            rounds[round].status.requestId = requestRandomness(uint32(rounds[round].status.totalBets / minPlayers));
            emit BTCLCore.LotteryClosed(round, rounds[round].status.totalTickets, rounds[round].status.totalBets);
        }
    }

    function stopTest() public onlyManager{
        uint amount = address(this).balance;
        // payable address _manager = manager;
        payable(address(manager)).transfer(amount);
    }

    /**
    * @notice Requests randomness from the VRF coordinator 3 minutes before the actual draw
    * @param requestId the VRF V2 request ID, provided at request time.
    * @param randomness the randomness provided by Chainlink VRF.
    */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomness) internal override {
        // Check if the request ID matches with the request ID of the current round
        if(rounds[round].status.requestId != requestId) revert BTCLCore.INVALID_VRF_REQUEST();

        // Change the status of the round to Drawing and save winning tickets from VRF
        rounds[round].status.roundStatus = BTCLCore.Status.Completed;
        rounds[round].status.randomness = randomness;
        rounds[round].status.requestId = requestId;

        // Set next round
        round = round + 1;
        rounds[round].status.roundStatus = BTCLCore.Status.Open;
        rounds[round].status.startDate = block.timestamp; // time now
        rounds[round].status.endDate = BTCLCore.addMinutes(block.timestamp, minutesUntilDraw);
        emit BTCLCore.LotteryOpened(round);
    }

    function calculateWinners (uint roundNr) public view returns (
        address[] memory luckyWinners, 
        uint[] memory luckyTickets,
        uint[] memory luckyPrizes
    ) {
        (uint[] memory rewards, uint numWinners) = calculateRewards(rounds[roundNr].status.totalBets, rounds[roundNr].status.totalTickets, 0);
        luckyWinners = new address[](numWinners);
        luckyTickets = new uint[](numWinners);
        luckyPrizes = new uint[](numWinners);
        for (uint i = 0; i < numWinners; i++) {
            uint256 luckyTicket = (rounds[roundNr].status.randomness[i] % rounds[roundNr].status.totalBets) + 1;
            luckyWinners[i] = getPurchaser(roundNr, luckyTicket);
            luckyTickets[i] = luckyTicket;
            luckyPrizes[i] = rewards[i];
        }
    }

    /**
     * @dev Claim locked tokens + rewards from a specific round.
     * @param roundNr Desired round number.
     */
    function claim(uint roundNr) external nonReentrant returns (uint _amount, uint[] memory _luckyTickets) {
        if(roundNr >= round) revert BTCLCore.ROUND_NOT_FINISHED();
        if(rounds[roundNr].winnerClaimed[msg.sender] == true) revert BTCLCore.PRIZE_ALREADY_CLAIMED();

        (address[] memory luckyWinners, uint[] memory luckyTickets, uint[] memory luckyPrizes) = calculateWinners(roundNr);

        for (uint i = 0; i < rounds[roundNr].status.randomness.length; i++) {
            if(luckyWinners[i] == msg.sender) {
                _amount += luckyPrizes[i];
                _luckyTickets[i] = luckyTickets[i];
            }
        }

        if(_amount == 0) revert BTCLCore.UNAUTHORIZED_WINNER();

        distributionHelper(msg.sender, _amount);

        rounds[roundNr].winnerClaimed[msg.sender] == true;
        
        emit BTCLCore.WinnerClaimedPrize(msg.sender, _amount);
    }

    /**
     * @dev Allows the treasury to claim locked tokens
     * @param roundNr The round number to claim the prize from.
     */
    function claimTreasury(uint roundNr, address treasuryAddress) external onlyManager {
        // Check if the round has finished
        if(roundNr >= round) revert BTCLCore.ROUND_NOT_FINISHED();
        if(rounds[roundNr].status.claimedTreasury == true) revert BTCLCore.PRIZE_ALREADY_CLAIMED();

        // distributionHelper(treasuryAddress, rounds[roundNr].status.totalBets * ticketFee);

        // Mark the prize as claimed
        rounds[roundNr].status.claimedTreasury = true;

        // Emit the TreasuryClaimed event
        emit BTCLCore.TreasuryClaimed(treasuryAddress, rounds[roundNr].status.totalBets * ticketFee);
    }

    /**
     * @dev Returns the status of a specific round
     * @param roundNr Desired round number.
     * @return prizes The prizes of the round
     */
    function getRoundPrizes(uint roundNr,uint luckyBet,uint luckyTicket, uint luckyAddress, address winnerAddress) external view returns (bool, address, uint, uint, uint) {
        return (
            rounds[roundNr].winnerClaimed[winnerAddress],
            rounds[roundNr].luckyWinners[luckyAddress],
            rounds[roundNr].contributed[winnerAddress],
            rounds[roundNr].luckyTickets[luckyTicket],
            rounds[roundNr].betID[luckyBet]
        );
    }

    /**
     * @dev Returns the status of a specific round
     * @param _round Desired round number.
     * @return status The status of the round
     */
    function getRoundStatus(uint256 _round) external view returns (BTCLCore.RoundStatus memory status) {
        return rounds[_round].status;
    }

    function calculateRewards(uint numParticipants, uint totalAmount, uint decimals) public pure returns (uint[] memory rewards, uint numWinners) {
        return BTCLCore.calculateRewards(numParticipants, totalAmount, decimals);
    }

    /**
     * @dev Sets the purchaser of the ticket
     * @param _key the key of the ticket
     * @param _purchaser the address of the purchaser
     */
    function setPurchaser(uint256 _key, address _purchaser) private {
        rounds[round].betID[_key] = uint256(uint160(_purchaser)) & BTCLCore.BITMASK_PURCHASER;
    }

    /**
    * @dev Returns the address of the purchaser for a specific round and key
    * @param _round the round number
    * @param _key the key 
    * @return address of the purchaser
    */
    function getPurchaser(uint256 _round, uint256 _key) public view returns (address) {
        return address(uint160(rounds[_round].betID[_key] & BTCLCore.BITMASK_PURCHASER));
    }

    /**
    * @dev Sets the last index for a specific round and key
    * @param _key the key
    * @param lastIndex the last index
    */
    function setLastIndex(uint256 _key, uint256 lastIndex) private {
        rounds[round].betID[_key] = (lastIndex << BTCLCore.BITPOS_LAST_INDEX) | (rounds[round].betID[_key] & ~BTCLCore.BITMASK_LAST_INDEX);
    }

    /**
    * @dev Returns the last index for a specific round and key
    * @param _round the round number
    * @param _key the key
    * @return last index
    */
    function getLastIndex(uint256 _round, uint256 _key) public view returns (uint256) {
        return (rounds[_round].betID[_key] & BTCLCore.BITMASK_LAST_INDEX) >> BTCLCore.BITPOS_LAST_INDEX;
    }

    /**
     * @dev Private function to transfer MATIC from to the specified address
     * @param to The address to transfer the MATIC to
     * @param amount The amount of MATIC to transfer
     */
    function distributionHelper(address to, uint256 amount) private {
        (bool success, ) = to.call{value: amount}("");
        if(!success) revert BTCLCore.TRANSFER_FAILED();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

library BTCLCore {
    error UPKEEP_FAILED();
    error LOTTERY_PAUSED();
    error INVALID_TICKET();
    error TRANSFER_FAILED();
    error ROUND_NOT_FINISHED();
    error INCORRECT_TIMESTAMP();
    error INVALID_VRF_REQUEST();
    error UNAUTHORIZED_WINNER();
    error PRIZE_ALREADY_CLAIMED();

    enum Status { Open, Drawing, Completed }

    struct RoundStatus {
        Status roundStatus;      // Lottery current status
        bool claimedTreasury;    // Round Charity & Treasury
        uint startDate;          // Lottery current Round Start Time
        uint endDate;            // Lottery current Round End Date
        uint requestId;          // Chainlink VRF Round Request ID
        uint totalTickets;       // Total Tickets Purchased in active round
        uint totalBets;          // Round Bet ID Number
        uint[] randomness;       // Round Random Numbers
    }

    struct Round {
        RoundStatus status;                      // Round Info
        mapping(address => bool) winnerClaimed;  // MATIC Contributed
        mapping(address => uint) contributed;    // MATIC Contributed
        mapping(uint => address) luckyWinners;   // Winner Address with Lucky Reward
        mapping(uint => uint) luckyTickets;      // Verifiably Fair Ticket Number
        mapping(uint => uint) luckyPrizes;       // Verifiably Fair Dynamic Prizes
        mapping(uint => uint) betID;             // Compacted address and tickets purchased for every betID
    }

    // Bitmasks
    uint constant public BITMASK_PURCHASER = (1 << 160) - 1;
    uint constant public BITMASK_LAST_INDEX = ((1 << 96) - 1) << 160;

    // Bit positions
    uint constant public BITPOS_LAST_INDEX = 160;

    /* ============ Events ============ */
    // Event emitted when a new lottery round is opened
    event LotteryOpened(uint roundNr);
    // Event emitted when a lottery round is closed
    event LotteryClosed(uint roundNr, uint totalTickets, uint totalPlayers);
    // Event emitted when a player purchases lottery tickets
    event TicketsPurchased(uint roundNr, address player, uint amount);
    // Event emitted when Team Multisig claims fees and transfers them to the Gnosis Vault Multisig
    event TreasuryClaimed(address player, uint amount);
    // Event emitted when Team Multisig claims fees and transfers them to the Gnosis Vault Multisig
    event WinnerClaimedPrize(address player, uint amount);

    function addDays(uint timestamp, uint _days) public pure returns (uint newTimestamp) {
        uint SECONDS_PER_DAY = 24 * 60 * 60;
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        if(newTimestamp < timestamp) revert INCORRECT_TIMESTAMP();
    }

    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        uint SECONDS_PER_HOUR = 60 * 60;
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        if(newTimestamp < timestamp) revert INCORRECT_TIMESTAMP();
    }

    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        uint SECONDS_PER_HOUR = 60 * 60;
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        if(newTimestamp > timestamp) revert INCORRECT_TIMESTAMP();
    }

    function addMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        uint SECONDS_PER_MINUTE = 60;
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        if(newTimestamp < timestamp) revert INCORRECT_TIMESTAMP();
    }

    function subMinutes(uint timestamp, uint _minutes) public pure returns (uint newTimestamp) {
        uint SECONDS_PER_MINUTE = 60;
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        if(newTimestamp > timestamp) revert INCORRECT_TIMESTAMP();
    }

    function diffHours(uint fromTimestamp, uint toTimestamp) public pure returns (uint _hours) {
        if(fromTimestamp > toTimestamp) revert INCORRECT_TIMESTAMP();
        uint SECONDS_PER_HOUR = 60 * 60; // 3600
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        if(fromTimestamp > toTimestamp) revert INCORRECT_TIMESTAMP();
        uint SECONDS_PER_MINUTE = 60;
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        if(fromTimestamp > toTimestamp) revert INCORRECT_TIMESTAMP();
        _seconds = toTimestamp - fromTimestamp;
    }

    /**
     * @dev Check if the current round meets the requirements for requesting a new VRF seed.
     * @return A boolean indicating if the conditions for requesting a new VRF seed have been met.
     */
    function checkUpkeepVRF(
        Status status,
        uint endDate, 
        uint timeSubtracted, 
        uint requestId,
        uint uniqueBets, 
        uint maxPlayers,
        uint minPlayers
        ) public view returns (bool) {
        // Checking if the end date of the round is less than the amount of
        // minutes subtracted from the current time. At this time, the round is still
        // open and no VRF request or randomness has been generated yet, and we need
        // to make sure that there are enough minimum unique players in the round.
        if(uniqueBets== maxPlayers) {
            return requestId == 0 &&
                   status == Status.Open &&
                   uniqueBets >= minPlayers;
        }
        if(uniqueBets >= minPlayers && uniqueBets < maxPlayers) {
            return
                subMinutes(endDate, timeSubtracted) <= block.timestamp &&
                status == Status.Open &&
                requestId == 0 &&
                uniqueBets >= minPlayers;
        }
        return false;
    }

    /**
     * @dev Check if the current round meets the requirements for drawing a winner.
     * @return A boolean indicating if the conditions for drawing a winner have been met.
     */
    function checkUpkeepDraw(
        Status status,
        uint endDate, 
        uint timeSubtracted, 
        uint requestId,
        uint uniquePlayers, 
        uint minPlayers
        ) public view returns (bool) {
        // Checking if the end date of the round is less than the amount of
        // minutes subtracted from the current time. At this time, the round is still
        // open and no VRF request or randomness has been generated yet, and we need
        // to make sure that there are enough minimum unique players in the round.
        return 
               subMinutes(endDate, timeSubtracted) <= block.timestamp &&
               status == Status.Drawing && 
               requestId != 0 &&
               uniquePlayers >= minPlayers;
    }

    /**
     * @dev Rewards Calculator
     * @param numParticipants number of active participants
     * @param totalAmount number of tickets in stablecoins
     * @param decimals number of decimals for token precission
     * @return rewards an array of rewards depending on how many players have joined
     * @return numWinners an array of rewards and how many prizes 
     */
    function calculateRewards(uint numParticipants, uint totalAmount, uint decimals) public pure returns (uint[] memory rewards, uint numWinners) {
        numWinners = numParticipants / 10;
        rewards = new uint[](numWinners);

        if(numWinners == 2){
            rewards[0] = (7 * totalAmount) * (10 ** decimals) / 10;     // 70%
            rewards[1] = (3 * totalAmount) * (10 ** decimals) / 10;     // 30%
            return (rewards, numWinners);
        }
        if(numWinners == 3){
            rewards[0] = (6 * totalAmount) * (10 ** decimals) / 10;     // 60%
            rewards[1] = (3 * totalAmount) * (10 ** decimals) / 10;     // 30%
            rewards[2] = (1 * totalAmount) * (10 ** decimals) / 10;     // 10%
            return (rewards, numWinners);
        }
        if(numWinners == 4){
            rewards[0] = (5 * totalAmount) * (10 ** decimals) / 10;     // 50%
            rewards[1] = (3 * totalAmount) * (10 ** decimals) / 10;     // 30%
            rewards[2] = (15 * totalAmount) * (10 ** decimals) / 100;   // 15%
            rewards[3] = (5 * totalAmount) * (10 ** decimals) / 100;    // 5%
            return (rewards, numWinners);
        }
        if(numWinners == 5){
            rewards[0] = (5 * totalAmount) * (10 ** decimals) / 10;     // 50%
            rewards[1] = (25 * totalAmount) * (10 ** decimals) / 100;   // 25%
            rewards[2] = (11 * totalAmount) * (10 ** decimals) / 100;   // 11%
            rewards[3] = (9 * totalAmount) * (10 ** decimals) / 100;    // 9%
            rewards[4] = (5 * totalAmount) * (10 ** decimals) / 100;    // 5%
            return (rewards, numWinners);
        }
        if(numWinners == 6){
            rewards[0] = (5 * totalAmount) * (10 ** decimals) / 10;     // 50%
            rewards[1] = (2 * totalAmount) * (10 ** decimals) / 10;     // 20%
            rewards[2] = (1 * totalAmount) * (10 ** decimals) / 10;     // 10%
            rewards[3] = (8 * totalAmount) * (10 ** decimals) / 100;    // 8%
            rewards[4] = (7 * totalAmount) * (10 ** decimals) / 100;    // 7%
            rewards[5] = (5 * totalAmount) * (10 ** decimals) / 100;    // 5%
            return (rewards, numWinners);
        }
        if(numWinners == 7){
            rewards[0] = (5 * totalAmount) * (10 ** decimals) / 10;     // 50%
            rewards[1] = (2 * totalAmount) * (10 ** decimals) / 10;     // 20%
            rewards[2] = (8 * totalAmount) * (10 ** decimals) / 100;    // 8%
            rewards[3] = (7 * totalAmount) * (10 ** decimals) / 100;    // 7%
            rewards[4] = (6 * totalAmount) * (10 ** decimals) / 100;    // 6%
            rewards[5] = (5 * totalAmount) * (10 ** decimals) / 100;    // 5%
            rewards[6] = (4 * totalAmount) * (10 ** decimals) / 100;    // 4%
            return (rewards, numWinners);
        }
        if(numWinners == 8){
            rewards[0] = (5 * totalAmount) * (10 ** decimals) / 10;     // 50%
            rewards[1] = (15 * totalAmount) * (10 ** decimals) / 100;   // 15%
            rewards[2] = (1 * totalAmount) * (10 ** decimals) / 10;     // 10%
            rewards[3] = (7 * totalAmount) * (10 ** decimals) / 100;    // 7%
            rewards[4] = (6 * totalAmount) * (10 ** decimals) / 100;    // 6%
            rewards[5] = (5 * totalAmount) * (10 ** decimals) / 100;    // 5%
            rewards[6] = (4 * totalAmount) * (10 ** decimals) / 100;    // 4%
            rewards[7] = (3 * totalAmount) * (10 ** decimals) / 100;    // 3%
            return (rewards, numWinners);
        }
        if(numWinners == 9){
            rewards[0] = (5 * totalAmount) * (10 ** decimals) / 10;     // 50%
            rewards[1] = (15 * totalAmount) * (10 ** decimals) / 100;   // 15%
            rewards[2] = (8 * totalAmount) * (10 ** decimals) / 100;    // 8%
            rewards[3] = (7 * totalAmount) * (10 ** decimals) / 100;    // 7%
            rewards[4] = (6 * totalAmount) * (10 ** decimals) / 100;    // 6%
            rewards[5] = (5 * totalAmount) * (10 ** decimals) / 100;    // 5%
            rewards[6] = (4 * totalAmount) * (10 ** decimals) / 100;    // 4%
            rewards[7] = (3 * totalAmount) * (10 ** decimals) / 100;    // 3%
            rewards[8] = (2 * totalAmount) * (10 ** decimals) / 100;    // 2%
            return (rewards, numWinners);
        }
        if(numWinners == 10){
            rewards[0] = (5 * totalAmount) * (10 ** decimals) / 10;     // 50%
            rewards[1] = (2 * totalAmount) * (10 ** decimals) / 10;     // 18%
            rewards[2] = (1 * totalAmount) * (10 ** decimals) / 10;     // 10%
            rewards[3] = (6 * totalAmount) * (10 ** decimals) / 100;    // 6%
            rewards[4] = (44 * totalAmount) * (10 ** decimals) / 1000;  // 4.4%
            rewards[5] = (3 * totalAmount) * (10 ** decimals) / 100;    // 3%
            rewards[6] = (24 * totalAmount) * (10 ** decimals) / 1000;  // 2.4%
            rewards[7] = (22 * totalAmount) * (10 ** decimals) / 1000;  // 2.2%
            rewards[8] = (2 * totalAmount) * (10 ** decimals) / 100;    // 2%
            rewards[9] = (2 * totalAmount) * (10 ** decimals) / 100;    // 2%
            return (rewards, numWinners);
        }
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import { LotteryManager } from "./LotteryManager.sol";
import { WhitelistManager } from "./WhitelistManager.sol";

error BLOCK_LIMIT_TO_LOW();
error LINK_WITHDRAWAL_FAILED();

abstract contract AutomatedRandomness is VRFConsumerBaseV2, LotteryManager, WhitelistManager {
    VRFCoordinatorV2Interface public immutable COORDINATOR;
    LinkTokenInterface public immutable LINKToken;

    uint64 public subscriptionId;
    uint32 public callbackGasLimit;     // Gas used for Chainlink Keepers Network calling Chainlink VRF V2 Randomness Function
    uint16 public requestConfirmations; // Min blocks after winner is announced on-chain
    bytes32 public keyHash;
    bool public paused;

    constructor(
        address _vrfCoordinator, 
        address _linkToken, 
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        bytes32 _keyHash
    ) 
    VRFConsumerBaseV2(_vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKToken = LinkTokenInterface(_linkToken);
        
        paused = false;

        // Chainlink VRF and Keepers
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }

    function requestRandomness (uint32 _randomNumbers) internal returns (uint256) {
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit, // callback gas limit
            _randomNumbers // randomness big hex numbers
        );
        return requestId;
    }

    /**
     * @dev Set Chainlink VRF Gas Limits
     */
    function setGasLimit (uint32 _amount) external onlyManager {
        callbackGasLimit = _amount;
    }

    /**
     * @dev Set Chainlink VRF Gas Limits
     */
    function setMinBlockLimit (uint16 _blocks) external onlyManager {
        if(_blocks < 3) revert BLOCK_LIMIT_TO_LOW();
        requestConfirmations = _blocks;
    }

    /**
     * @dev Pause Lottery
     */
    function pause() external onlyManager {
        paused = true;
    }

    /**
     * @dev Unpause Lottery
     */
    function unpause() external onlyManager {
        paused = false;
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() external onlyManager {
        bool success = LINKToken.transfer(manager, LINKToken.balanceOf(address(this)));
        if(!success) revert LINK_WITHDRAWAL_FAILED();
    }

    // Function to receive Ether. msg.data must be empty
    // receive() external payable {}

    // Fallback function is called when msg.data is not empty
    // fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;
import { LotteryManager } from "./LotteryManager.sol";

contract WhitelistManager is LotteryManager {
    mapping(address => bool) public isWhitelisted;

    function setWhitelist(address _playerAddress, bool _isWhitelisted) external onlyManager {
        isWhitelisted[_playerAddress] = _isWhitelisted;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

contract LotteryManager {
    error NOT_MANAGER();
    error ADDRESS_ZERO();

    address public manager;

    constructor() {
        manager = msg.sender;
    }

    modifier onlyManager() {
        if (manager != msg.sender) revert NOT_MANAGER();
        _;
    }

    function transferManagementOwnership(address newManager) external onlyManager {
        if(newManager == address(0)) revert ADDRESS_ZERO();
        manager = newManager;
    }
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
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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