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
        uint256 proportion; // This field represents the stake proportion of a staker
        bool isStaker; // This field checks if an address is a staker
    }

    mapping(uint256 => BetStatus) public statuses;
    mapping(address => StakeInfo) public stakes;
    address[] public stakers;
    uint256 public houseStake;
    uint256 public nonce;

    uint constant entryFees = 0.000000000001 ether;

    function placeBet(BetSelection choice) external payable returns (uint) {
        require(msg.value >= entryFees, "entry too low");

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

    function determineWinner(uint256 requestId) internal {
        BetStatus storage bet = statuses[requestId];
        require(bet.blockNumber > 0, "Bet doesn't exist");

        // Simple pseudo-random number generator. Do not use in production.
        uint256 randomWord = uint256(
            keccak256(abi.encodePacked(block.timestamp, bet.betAmount))
        );
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
        uint256 payoutAmount;
        if (bet.choice == result) {
            // Winning case
            // Winning case
            bet.didWin = true;
            uint256 transferAmount = (bet.betAmount * rate) / 100;
            require(
                address(this).balance >= transferAmount,
                "Not enough balance in the contract"
            );
            payable(bet.player).transfer(transferAmount);
            int256 winnings = int256(transferAmount - bet.betAmount);
            distributeStakeResults(-winnings);
            houseStake -= transferAmount;

            // Update proportions for all stakers
            for (uint256 i = 0; i < stakers.length; i++) {
                address staker = stakers[i];
                stakes[staker].proportion =
                    (uint256(stakes[staker].balance) * 1e18) /
                    houseStake;
            }

            payoutAmount = transferAmount;
            emit BetOutcome(
                bet.player,
                bet.blockNumber,
                bet.didWin,
                bet.betAmount,
                payoutAmount
            );
            return winnings;
        } else {
            // Losing case
            int256 losses = -int256(bet.betAmount);
            distributeStakeResults(-losses);
            houseStake += bet.betAmount;

            // Update proportions for all stakers
            for (uint256 i = 0; i < stakers.length; i++) {
                address staker = stakers[i];
                stakes[staker].proportion =
                    (uint256(stakes[staker].balance) * 1e18) /
                    houseStake;
            }

            payoutAmount = bet.betAmount;
            emit BetOutcome(
                bet.player,
                bet.blockNumber,
                bet.didWin,
                bet.betAmount,
                payoutAmount
            );
            return losses;
        }
    }

    function distributeStakeResults(int256 netResult) internal {
        for (uint256 i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            int256 stakerResult = (netResult *
                int256(stakes[staker].proportion)) / int256(houseStake);
            stakes[staker].balance += stakerResult;

            // Ensure that the stake balance doesn't go below zero
            if (stakes[staker].balance < 0) {
                stakes[staker].balance = 0;
            }
        }
    }

    function stake() public payable {
        // Update total staked amount first
        houseStake += msg.value;

        // Then, update the staker's balance
        stakes[msg.sender].balance += int256(msg.value);

        // Add the staker to the list of stakers if they are not already on it
        if (!stakes[msg.sender].isStaker) {
            stakes[msg.sender].isStaker = true;
            stakers.push(msg.sender);
        }

        // Update proportions for all stakers
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

        // Update house stake and staker's balance
        houseStake -= _amount;
        stakes[msg.sender].balance -= int256(_amount);

        // Update proportions for all stakers
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