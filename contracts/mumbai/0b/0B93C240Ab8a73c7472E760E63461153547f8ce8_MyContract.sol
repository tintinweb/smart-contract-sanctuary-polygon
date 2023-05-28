// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    event BetRequest(uint indexed requestId, uint indexed nonce);
    event BetResult(BetSelection indexed result, uint indexed blockNumber);
    event BetOutcome(
        address indexed player,
        uint indexed requestId,
        bool didWin,
        uint betAmount,
        uint payoutAmount
    );

    enum BetSelection {
        Banker,
        Player,
        Tie
    }

    struct BetStatus {
        uint blockNumber;
        uint nonce;
        address player;
        bool didWin;
        bool fulfilled;
        BetSelection choice;
        uint betAmount;
    }

    struct StakeInfo {
        int256 balance;
        uint256 proportion;
        bool isStaker;
    }

    mapping(uint256 => BetStatus) public statuses;
    mapping(address => StakeInfo) public stakes;
    address[] public stakers;
    uint256 public houseStake;
    uint256 public nonce;

    uint constant entryFees = 0.000000000001 ether;

    function placeBet(BetSelection choice) external payable returns (uint) {
        require(msg.value >= entryFees, "entry too low");

        uint possibleWinningAmount = calculatePossibleWinningAmount(
            msg.value,
            choice
        );

        require(
            possibleWinningAmount <= houseStake,
            "House stake too low to cover the possible winning amount"
        );

        uint256 requestId = block.number;

        nonce++;

        statuses[requestId] = BetStatus({
            blockNumber: requestId,
            nonce: nonce,
            player: msg.sender,
            didWin: false,
            fulfilled: false,
            choice: choice,
            betAmount: msg.value
        });

        emit BetRequest(requestId, nonce);

        determineWinner(requestId);

        return requestId;
    }

    function calculatePossibleWinningAmount(
        uint betAmount,
        BetSelection choice
    ) internal pure returns (uint) {
        if (choice == BetSelection.Banker) {
            return (betAmount * 195) / 100;
        } else if (choice == BetSelection.Player) {
            return (betAmount * 200) / 100;
        } else if (choice == BetSelection.Tie) {
            return (betAmount * 900) / 100;
        } else {
            revert("Invalid bet selection");
        }
    }

    function determineWinner(uint256 requestId) internal {
        BetStatus storage bet = statuses[requestId];
        require(bet.blockNumber > 0, "Bet doesn't exist");

        uint256 randomWord = uint256(
            keccak256(abi.encodePacked(block.timestamp, bet.betAmount))
        );
        bet.fulfilled = true;

        uint256 scaledNumber = randomWord % 10000;
        BetSelection result;

        if (scaledNumber < 4586) {
            result = BetSelection.Banker;
        } else if (scaledNumber < 9048) {
            result = BetSelection.Player;
        } else {
            result = BetSelection.Tie;
        }

        uint256 netResult;

        // Calculate winnings and update balances
        if (bet.choice == result) {
            bet.didWin = true;
            uint256 transferAmount = (bet.betAmount * 195) / 100;
            require(
                address(this).balance >= transferAmount,
                "Not enough balance in the contract"
            );
            payable(bet.player).transfer(transferAmount);
            netResult = uint256(transferAmount - bet.betAmount);
            distributePlayerWins(netResult);
        } else {
            distributePlayerLoose(bet.betAmount);
            bet.didWin = false;
        }

        emit BetOutcome(
            bet.player,
            bet.blockNumber,
            bet.didWin,
            bet.betAmount,
            netResult
        );

        emit BetResult(result, bet.blockNumber);
    }

    function distributePlayerWins(uint256 netResult) internal {
        houseStake -= netResult;

        for (uint256 i = 0; i < stakers.length; i++) {
            stakes[stakers[i]].balance -= int256(
                (stakes[stakers[i]].proportion * netResult) / 10000
            );
        }
    }

    function distributePlayerLoose(uint256 betAmount) internal {
        houseStake += betAmount;

        for (uint256 i = 0; i < stakers.length; i++) {
            stakes[stakers[i]].balance += int256(
                (stakes[stakers[i]].proportion * betAmount) / 10000
            );
        }
    }

    function stake() public payable {
        stakes[msg.sender].balance += int256(msg.value); // Update staker's balance first
        houseStake += msg.value; // Update total staked amount

        if (!stakes[msg.sender].isStaker) {
            stakes[msg.sender].isStaker = true;
            stakers.push(msg.sender);
        }

        // Update proportions for all stakers based on updated balances and house stake
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            stakes[staker].proportion =
                (uint256(stakes[staker].balance) * 1e18) /
                houseStake;
        }
    }

    function withdrawStake(uint256 _amount) public {
        require(
            stakes[msg.sender].balance >= int256(_amount),
            "Insufficient staked amount"
        );

        // Update staker's balance and house stake first
        stakes[msg.sender].balance -= int256(_amount);
        houseStake -= _amount;

        // Update proportions for all stakers based on updated balances and house stake
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            stakes[staker].proportion =
                (uint256(stakes[staker].balance) * 1e18) /
                houseStake;
        }

        payable(msg.sender).transfer(_amount);
    }

    function getStakerBalance(address staker) public view returns (int256) {
        return stakes[staker].balance;
    }

    function getHouseStake() public view returns (uint256) {
        return houseStake;
    }

    function getStakeProportionPercentage(
        address staker
    ) public view returns (uint256) {
        return (stakes[staker].proportion);
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
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }
}