// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract LuckyTickets {
    uint256 public constant ticketPrice = 0.01 ether;
    uint256 public constant ticketCommission = 0.001 ether;
    uint256 public constant duration = 24 hours;

    uint256 public expiration;
    address public lotteryOperator;
    uint256 public operatorTotalCommission = 0;
    address[] public tickets;
    mapping(address => uint256) public winnings;
    address public lastWinner;
    uint256 public lastWinnerAmount;

    constructor() {
        lotteryOperator = msg.sender;
        expiration = block.timestamp + duration;
    }

    modifier isNotOperator() {
        require(
            (msg.sender != lotteryOperator),
            "Caller is the lottery operator!"
        );
        _;
    }

    modifier isOperator() {
        require(
            (msg.sender == lotteryOperator),
            "Caller is the not lottery operator!"
        );
        _;
    }

    modifier isWinner() {
        require(
            senderIsWinner(),
            "Caller is the not lottery operator!"
        );
        _;
    }

    function buyTickets () public payable isNotOperator {
        require(
            msg.value % ticketPrice == 0,
            "The value must be multiple of 0.01"
        );
        uint256 numOfTicketsToBuy = msg.value / ticketPrice;
        for (uint256 i = 0; i < numOfTicketsToBuy; i++) {
            tickets.push(msg.sender);
        }
    }

    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function getWinningsForAddress(address addr) public view returns (uint256) {
        return winnings[addr];
    }

    function senderIsWinner() public view returns (bool) {
        return winnings[msg.sender] > 0;
    }

    function drawWinnerTicket() public isOperator {
        require(tickets.length > 0, "No tickets were purchased");
        bytes32 blockHash = blockhash(block.number - tickets.length);
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, blockHash))
        );
        uint256 winningTicket = randomNumber % tickets.length;

        address winner = tickets[winningTicket];
        lastWinner = winner;
        winnings[winner] += (tickets.length * (ticketPrice - ticketCommission)); 
        lastWinnerAmount = winnings[winner];
        operatorTotalCommission += (tickets.length * ticketCommission);
        delete tickets;
        expiration = block.timestamp + duration;
    }

    function restartDraw() public isOperator {
        require(tickets.length == 0, "Cannot restart draw as draw is in play");
        
        delete tickets;
        expiration = block.timestamp + duration;
    }

    function withdrawComission() public isOperator {
        address payable operator = payable(msg.sender);
        uint256 commission2Transfer = operatorTotalCommission;
        operatorTotalCommission = 0;
        operator.transfer(commission2Transfer);
    }

    function withdrawWinnings() public isWinner {
        address payable winner = payable(msg.sender);
        uint256 reward2Transfer = winnings[msg.sender];
        winnings[msg.sender] = 0;
        winner.transfer(reward2Transfer);
    }

    function currentWinningReward() public view returns (uint256) {
        return tickets.length * (ticketPrice - ticketCommission);
    }
}