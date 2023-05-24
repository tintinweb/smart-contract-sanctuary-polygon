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
        uint256 balance;
    }

    mapping(uint256 => BetStatus) public statuses;
    mapping(address => StakeInfo) public stakes;
    uint256 public houseStake;

    uint constant entryFees = 0.000000000001 ether;

    function placeBet(BetSelection choice) external payable returns (uint) {
        require(msg.value >= entryFees, "entry too low");

        uint256 requestId = block.number;

        houseStake += msg.value;
        stakes[msg.sender].stake += msg.value;
        stakes[msg.sender].balance =
            (stakes[msg.sender].stake * 1e18) /
            houseStake;

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

        if (scaledNumber < 4586) {
            result = BetSelection.Banker;
            if (bet.choice == result) {
                bet.didWin = true;
                uint256 transferAmount = (bet.betAmount * 195) / 100;
                require(
                    address(this).balance >= transferAmount,
                    "Not enough balance in the contract"
                );
                payable(bet.player).transfer(transferAmount);
                houseStake -= transferAmount;
                stakes[bet.player].stake -= transferAmount;
                stakes[bet.player].balance =
                    (stakes[bet.player].stake * 1e18) /
                    houseStake;
                emit BetOutcome(bet.player, requestId, true, transferAmount);
            } else {
                // Losing case
                emit BetOutcome(bet.player, requestId, false, bet.betAmount);
            }
        } else if (scaledNumber < 9048) {
            result = BetSelection.Player;
            if (bet.choice == result) {
                bet.didWin = true;
                uint256 transferAmount = (bet.betAmount * 200) / 100;
                require(
                    address(this).balance >= transferAmount,
                    "Not enough balance in the contract"
                );
                payable(bet.player).transfer(transferAmount);
                houseStake -= transferAmount;
                stakes[bet.player].stake -= transferAmount;
                stakes[bet.player].balance =
                    (stakes[bet.player].stake * 1e18) /
                    houseStake;
                emit BetOutcome(bet.player, requestId, true, transferAmount);
            } else {
                // Losing case
                emit BetOutcome(bet.player, requestId, false, bet.betAmount);
            }
        } else {
            result = BetSelection.Tie;
            if (bet.choice == result) {
                bet.didWin = true;
                uint256 transferAmount = (bet.betAmount * 900) / 100;
                require(
                    address(this).balance >= transferAmount,
                    "Not enough balance in the contract"
                );
                payable(bet.player).transfer(transferAmount);
                houseStake -= transferAmount;
                stakes[bet.player].stake -= transferAmount;
                stakes[bet.player].balance =
                    (stakes[bet.player].stake * 1e18) /
                    houseStake;
                emit BetOutcome(bet.player, requestId, true, transferAmount);
            } else {
                // Losing case
                emit BetOutcome(bet.player, requestId, false, bet.betAmount);
            }
        }

        emit BetResult(result, bet.blockNumber);
    }

    function Stake() public payable {
        // Update total staked amount first
        houseStake += msg.value;

        // Then, update the staker's stake and balance
        stakes[msg.sender].stake += msg.value;
        stakes[msg.sender].balance =
            (stakes[msg.sender].stake * 1e18) /
            houseStake;
    }

    function withdrawStake(uint256 _amount) public {
        require(
            stakes[msg.sender].stake >= _amount,
            "Insufficient staked amount"
        );
        stakes[msg.sender].stake -= _amount;
        houseStake -= _amount;
        payable(msg.sender).transfer(_amount);

        // Update the staker's balance
        stakes[msg.sender].balance =
            (stakes[msg.sender].stake * 1e18) /
            houseStake;
    }

    function balanceOf(address staker) public view returns (uint256) {
        return (stakes[staker].balance * houseStake) / 1e18;
    }

    function balanceOfHouse() public view returns (uint) {
        return houseStake;
    }

    function getHouseStake() public view returns (uint256) {
        return houseStake;
    }

    function getStake(address player) public view returns (uint256) {
        return stakes[player].stake;
    }

    function getBalance(address player) public view returns (uint256) {
        return stakes[player].balance;
    }

    // A function to check the status of a bet.
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

    // A function to allow the owner to withdraw the profits of the house.
    function houseWithdraw(uint256 amount) public onlyOwner {
        require(amount <= houseStake, "Withdraw amount exceeds house stake");
        houseStake -= amount;
        payable(owner).transfer(amount);
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
}