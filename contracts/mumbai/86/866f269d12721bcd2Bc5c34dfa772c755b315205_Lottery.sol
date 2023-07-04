// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address payable public manager;
    address payable[] public players;
    uint public totalBet;

    uint constant MIN_BET = 0.001 ether;
    uint constant MAX_BET = 5 ether;
    uint constant MAX_PLAYERS = 5;
    uint constant PERCENT_TAKEN = 5;  // 5% fee

    event PlayerEntered(address player);
    event WinnerPicked(address winner, uint winnings);

    constructor(address _manager) {
        manager = payable(_manager);
    }

    function enter() public payable {
        require(msg.value >= MIN_BET && msg.value <= MAX_BET, "The bet amount is out of range");

        players.push(payable(msg.sender));
        totalBet += msg.value;

        emit PlayerEntered(msg.sender);

        if (players.length == MAX_PLAYERS) {
            pickWinner();
        }
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() private {
        require(players.length > 0);

        uint index = calculateWinner();
        uint amount = address(this).balance;
        uint fee = (amount * PERCENT_TAKEN) / 100;

        (bool success, ) = (manager).call{value:fee}(''); // Send fee to manager
        require(success, "Transfer failed.");
        players[index].transfer(amount - fee); // Send the rest to winner

        emit WinnerPicked(players[index], amount - fee);

        players = new address payable[](0);
        totalBet = 0;
    }

    function calculateWinner() private view returns(uint) {
        uint winnerWeight = random() % totalBet;
        uint currentSum = 0;
        uint winnerIndex = 0;

        for (uint i = 0; i < players.length; i++) {
            address playerAddress = players[i];
            uint playerBalance = playerAddress.balance;

            if (currentSum + playerBalance >= winnerWeight) {
                winnerIndex = i;
                break;
            } else {
                currentSum += playerBalance;
            }
        }

        return winnerIndex;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }
}