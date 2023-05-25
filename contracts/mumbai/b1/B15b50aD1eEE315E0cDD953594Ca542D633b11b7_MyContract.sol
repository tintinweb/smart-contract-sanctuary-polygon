// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    event BetRequest(uint indexed requestId);
    event BetResult(BetSelection indexed result, uint indexed blockNumber);
    event BetOutcome(
        address indexed player,
        uint indexed requestId,
        bool didWin,
        uint winnings
    );

    enum BetSelection {
        Banker,
        Player,
        Tie
    }

    struct BetStatus {
        uint blockNumber;
        address player;
        bool didWin;
        bool fulfilled;
        BetSelection choice;
        uint betAmount;
    }

    struct StakeInfo {
        uint256 stake;
        int256 balance;
    }

    mapping(uint256 => BetStatus) public statuses;
    mapping(address => StakeInfo) public stakes;
    address[] public stakers;
    uint256 public houseStake;

    uint constant entryFees = 0.000000000001 ether;

    function placeBet(BetSelection choice) external payable returns (uint) {
        require(msg.value >= entryFees, "entry too low");

        uint256 requestId = block.number;

        houseStake += msg.value;

        statuses[requestId] = BetStatus({
            blockNumber: requestId,
            player: msg.sender,
            didWin: false,
            fulfilled: false,
            choice: choice,
            betAmount: msg.value
        });

        emit BetRequest(requestId);

        determineWinner(requestId);

        return requestId;
    }

    function determineWinner(uint256 requestId) internal {
        BetStatus storage bet = statuses[requestId];

        require(bet.blockNumber > 0, "Bet doesn't exist");

        uint256 randomWord = uint256(blockhash(bet.blockNumber));

        bet.fulfilled = true;

        uint256 scaledNumber = randomWord % 10000;
        BetSelection result;
        int256 netResult;

        // Calculate winnings and update balances
        if (scaledNumber < 4586) {
            result = BetSelection.Banker;
            netResult = calculateBetOutcome(bet, result, 195);
        } else if (scaledNumber < 9048) {
            result = BetSelection.Player;
            netResult = calculateBetOutcome(bet, result, 200);
        } else {
            result = BetSelection.Tie;
            netResult = calculateBetOutcome(bet, result, 900);
        }

        distributeStakeResults(-netResult);

        emit BetResult(result, bet.blockNumber);
    }

    function calculateBetOutcome(
        BetStatus storage bet,
        BetSelection result,
        uint rate
    ) internal returns (int256) {
        if (bet.choice == result) {
            bet.didWin = true;
            uint256 transferAmount = (bet.betAmount * rate) / 100;
            require(
                address(this).balance >= transferAmount,
                "Not enough balance in the contract"
            );
            payable(bet.player).transfer(transferAmount);
            houseStake -= transferAmount;
            emit BetOutcome(bet.player, bet.blockNumber, true, transferAmount);
            return int256(transferAmount - bet.betAmount);
        } else {
            // Losing case
            emit BetOutcome(bet.player, bet.blockNumber, false, bet.betAmount);
            return -int256(bet.betAmount);
        }
    }

    function distributeStakeResults(int256 netResult) internal {
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            int256 stakerResult = (netResult * int256(stakes[staker].stake)) /
                int256(houseStake);
            stakes[staker].balance += stakerResult;
        }
    }

    function stake() public payable {
        if (stakes[msg.sender].stake == 0) {
            stakers.push(msg.sender);
        }
        houseStake += msg.value;
        stakes[msg.sender].stake += msg.value;
        stakes[msg.sender].balance += int256(msg.value);
    }

    function withdrawStake(uint256 _amount) public {
        int256 netBalance = int256(stakes[msg.sender].stake) +
            stakes[msg.sender].balance;
        require(netBalance >= int256(_amount), "Insufficient staked amount");
        if (int256(stakes[msg.sender].stake) >= int256(_amount)) {
            stakes[msg.sender].stake -= _amount;
        } else {
            stakes[msg.sender].balance -=
                int256(_amount) -
                int256(stakes[msg.sender].stake);
            stakes[msg.sender].stake = 0;
        }
        houseStake -= _amount;
        payable(msg.sender).transfer(_amount);

        // Update the staker's balance
        stakes[msg.sender].balance =
            (int256(stakes[msg.sender].stake) * int256(houseStake)) /
            int256(houseStake);
    }

    function getStakerBalance(address staker) public view returns (int256) {
        return stakes[staker].balance;
    }

    function getHouseStake() public view returns (uint256) {
        return houseStake;
    }

    function checkBetStatus(
        uint256 requestId
    )
        public
        view
        returns (
            bool didWin,
            bool fulfilled,
            BetSelection choice,
            uint betAmount
        )
    {
        BetStatus storage bet = statuses[requestId];
        return (bet.didWin, bet.fulfilled, bet.choice, bet.betAmount);
    }

    // Owner of the contract
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // A function to allow the owner to withdraw the profits of the house.
    function houseWithdraw(uint256 amount) public onlyOwner {
        require(amount <= houseStake, "Withdraw amount exceeds house stake");
        houseStake -= amount;
        payable(owner).transfer(amount);
    }
}