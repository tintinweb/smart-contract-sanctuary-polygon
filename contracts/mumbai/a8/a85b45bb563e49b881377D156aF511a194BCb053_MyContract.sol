// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    event BetRequest(uint indexed requestId);
    event BetResult(BetSelection indexed result, uint indexed blockNumber);

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

    uint constant entryFees = 0.001 ether;

    function placeBetbet(BetSelection choice) external payable returns (uint) {
        require(msg.value >= entryFees, "entry too low");

        uint256 requestId = block.number;

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
                houseStake = houseStake - transferAmount;
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
                houseStake = houseStake - transferAmount;
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
                houseStake = houseStake - transferAmount;
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
    // rest of the contract
}