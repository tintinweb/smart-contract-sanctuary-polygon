// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Lottery.sol";

contract CasinoManager {
    address payable public owner1;
    address payable public owner2;

    mapping(address => uint256) public balances;

    // переменная для отслеживания общего количества полученного ETH
    uint256 public totalReceived = 0;

    // Event declaration
    event Deposit(address indexed sender, uint256 value);
    event Withdraw(address indexed receiver, uint256 value);
    event OwnersBalanceChanged(address indexed owner1, uint256 balance1, address indexed owner2, uint256 balance2);

    constructor(address payable _owner1, address payable _owner2) {
        owner1 = _owner1;
        owner2 = _owner2;
    }

    receive() external payable {
        totalReceived += msg.value;
        emit Deposit(msg.sender, msg.value); // Emit deposit event

        if (totalReceived <= 10 ether) {
            balances[owner1] += msg.value;
        } else if (totalReceived > 10 ether && totalReceived <= 20 ether) {
            balances[owner1] += msg.value / 2;
            balances[owner2] += msg.value / 2;
        } else if (totalReceived > 20 ether) {
            uint256 twentyPercent = (msg.value * 20) / 100;
            uint256 eightyPercent = msg.value - twentyPercent;

            balances[owner1] += twentyPercent;
            balances[owner2] += eightyPercent;
        }

        // Emit balance change event
        emit OwnersBalanceChanged(owner1, balances[owner1], owner2, balances[owner2]);
    }

    function withdraw() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "You have no funds to withdraw");

        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        // Emit withdraw event
        emit Withdraw(msg.sender, amount);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

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