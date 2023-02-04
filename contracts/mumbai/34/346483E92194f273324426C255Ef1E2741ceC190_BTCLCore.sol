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

        if(numWinners == 1){
            rewards[0] = (10 * totalAmount) * (10 ** decimals / 10);     // 100%
            return (rewards, numWinners);
        }
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
            rewards[3] = (50 * totalAmount) * (10 ** decimals) / 1000;  // 5%
            return (rewards, numWinners);
        }
        if(numWinners == 5){
            rewards[0] = (5 * totalAmount) * (10 ** decimals) / 10;     // 50%
            rewards[1] = (25 * totalAmount) * (10 ** decimals) / 100;   // 25%
            rewards[2] = (11 * totalAmount) * (10 ** decimals) / 100;   // 11%
            rewards[3] = (90 * totalAmount) * (10 ** decimals) / 1000;  // 9%
            rewards[4] = (50 * totalAmount) * (10 ** decimals) / 1000;  // 5%
            return (rewards, numWinners);
        }
        if(numWinners == 6){
            rewards[0] = (5 * totalAmount) * (10 ** decimals) / 10;     // 50%
            rewards[1] = (2 * totalAmount) * (10 ** decimals) / 10;     // 20%
            rewards[2] = (1 * totalAmount) * (10 ** decimals) / 10;     // 10%
            rewards[3] = (80 * totalAmount) * (10 ** decimals) / 1000;  // 8%
            rewards[4] = (70 * totalAmount) * (10 ** decimals) / 1000;  // 7%
            rewards[5] = (50 * totalAmount) * (10 ** decimals) / 1000;  // 5%
            return (rewards, numWinners);
        }
        if(numWinners == 7){
            rewards[0] = (5 * totalAmount) * (10 ** decimals) / 10;     // 50%
            rewards[1] = (2 * totalAmount) * (10 ** decimals) / 10;     // 20%
            rewards[2] = (80 * totalAmount) * (10 ** decimals) / 1000;  // 8%
            rewards[3] = (70 * totalAmount) * (10 ** decimals) / 1000;  // 7%
            rewards[4] = (60 * totalAmount) * (10 ** decimals) / 1000;  // 6%
            rewards[5] = (50 * totalAmount) * (10 ** decimals) / 1000;  // 5%
            rewards[6] = (40 * totalAmount) * (10 ** decimals) / 1000;  // 4%
            return (rewards, numWinners);
        }
        if(numWinners == 8){
            rewards[0] = (5 * totalAmount) * (10 ** decimals) / 10;     // 50%
            rewards[1] = (15 * totalAmount) * (10 ** decimals) / 100;   // 15%
            rewards[2] = (1 * totalAmount) * (10 ** decimals) / 10;     // 10%
            rewards[3] = (70 * totalAmount) * (10 ** decimals) / 1000;  // 7%
            rewards[4] = (60 * totalAmount) * (10 ** decimals) / 1000;  // 6%
            rewards[5] = (50 * totalAmount) * (10 ** decimals) / 1000;  // 5%
            rewards[6] = (40 * totalAmount) * (10 ** decimals) / 1000;  // 4%
            rewards[7] = (30 * totalAmount) * (10 ** decimals) / 1000;  // 3%
            return (rewards, numWinners);
        }
        if(numWinners == 9){
            rewards[0] = (5 * totalAmount) * (10 ** decimals) / 10;     // 50%
            rewards[1] = (15 * totalAmount) * (10 ** decimals) / 100;   // 15%
            rewards[2] = (80 * totalAmount) * (10 ** decimals) / 1000;  // 8%
            rewards[3] = (70 * totalAmount) * (10 ** decimals) / 1000;  // 7%
            rewards[4] = (60 * totalAmount) * (10 ** decimals) / 1000;  // 6%
            rewards[5] = (50 * totalAmount) * (10 ** decimals) / 1000;  // 5%
            rewards[6] = (40 * totalAmount) * (10 ** decimals) / 1000;  // 4%
            rewards[7] = (30 * totalAmount) * (10 ** decimals) / 1000;  // 3%
            rewards[8] = (20 * totalAmount) * (10 ** decimals) / 1000;  // 2%
            return (rewards, numWinners);
        }
        if(numWinners == 10){
            rewards[0] = (5 * totalAmount) * (10 ** decimals) / 10;     // 50%
            rewards[1] = (2 * totalAmount) * (10 ** decimals) / 10;     // 20%
            rewards[2] = (1 * totalAmount) * (10 ** decimals) / 10;     // 10%
            rewards[3] = (60 * totalAmount) * (10 ** decimals) / 1000;  // 6%
            rewards[4] = (44 * totalAmount) * (10 ** decimals) / 1000;  // 4.4%
            rewards[5] = (30 * totalAmount) * (10 ** decimals) / 1000;  // 3%
            rewards[6] = (20 * totalAmount) * (10 ** decimals) / 1000;  // 2%
            rewards[7] = (18 * totalAmount) * (10 ** decimals) / 1000;  // 1.8%
            rewards[8] = (16 * totalAmount) * (10 ** decimals) / 1000;  // 1.6%
            rewards[9] = (12 * totalAmount) * (10 ** decimals) / 1000;  // 1.2%
            return (rewards, numWinners);
        }
    }

}