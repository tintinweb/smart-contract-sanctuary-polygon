/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

// SPDX-License-Identifier: MIT 
 
 /*   Multimatic Lottery - A simple lottery with all proceeds routed to the Multimatic staking rewards pool
 
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect browser extension Metamask (see help: https://medium.com/stakingbits/setting-up-metamask-for-polygon-matic-network-838058f6d844 )
 *   2) Enter the number of lottery tickets to buy and click "Buy Now"
 *   3) Prizes are sent to winning ticket holders automatically. Check your wallet and/or the "Latest Winners" section to see if you won a prize!
 *
 *   [TICKET PURCHASE CONDITIONS]
 *
 *   - Maximum 5 tickets per purchase, no maximum number of purchases.
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 25% Grand prize (1 winner)
 *   - 25% Small prizes (10 winners)
 *   - 50% Multimatic staking rewards pool
 */

pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
	using SafeMath for uint256;

    string public name = "Multimatic Lottery";

    uint256 constant public MAX_TICKETS = 100;
    uint256 constant public TICKET_PRICE = 10 ether;
    uint256 constant public GRAND_PRIZE = 250 ether;
    uint256 constant public SMALL_PRIZE = 25 ether;
    uint256 constant public SMALL_PRIZES = 10;
    uint256 constant public MIN_FOR_DRAW = 1000 ether;

    uint256 public ticketsSold;
    uint256 public seed;

    address[] public ticketHolders;
    address[] public winnerHistory;
    address[] public runnerHistory;

    address payable public rewardsPool;

    event TicketsSoldTo(address buyer, uint256 tickets);
    event GrandPrizeWinner(address winner, uint256 amount);
    event SmallPrizeWinner(address winner, uint256 amount);
    event RemainderPaidTo(address pool, uint256 amount);

    constructor(address pool) {
        rewardsPool = payable(pool);
    }

    function buy(uint256 tickets) public payable {
		require(tickets > 0, "Invalid argument tickets (min 1).");
        require(tickets < 6, "Invalid argument tickets (max 5).");
        require(ticketsSold + tickets <= MAX_TICKETS, "SOLD OUT");
        require(msg.value == tickets.mul(TICKET_PRICE), "Paid incorrect amount");

        for (uint256 i = 0; i < tickets; i++) {
            ticketHolders.push(msg.sender);
        }
        emit TicketsSoldTo(msg.sender, tickets);

        ticketsSold = ticketsSold.add(tickets);

        if(ticketsSold == MAX_TICKETS) {
            draw();
        }
    }

    function draw() private {
        require(ticketHolders.length == MAX_TICKETS, "Min holders for draw not met");
        require(address(this).balance >= MIN_FOR_DRAW, "Min balance for draw not met");

        address payable winner = payable(ticketHolders[random(MAX_TICKETS)]);
        winner.transfer(GRAND_PRIZE);
        winnerHistory.push(winner);
        emit GrandPrizeWinner(winner, GRAND_PRIZE);

        for (uint256 i = 0; i < SMALL_PRIZES; i++) {
            address payable runner = payable(ticketHolders[random(MAX_TICKETS)]);
            runner.transfer(SMALL_PRIZE);
            runnerHistory.push(runner);
            emit SmallPrizeWinner(runner, SMALL_PRIZE);
        }

        uint256 remainder = address(this).balance;
        rewardsPool.transfer(remainder);
        emit RemainderPaidTo(rewardsPool, remainder);
        
        ticketsSold = 0;
        delete ticketHolders;
    }

    function random(uint256 range) public returns(uint256 r){
        r = uint256(keccak256(abi.encodePacked(seed++))) % range;
    }

    function getTicketHolder(uint256 i) public view returns (address holder) {
        return ticketHolders[i];
    }

    function getTicketHolders() public view returns (address[] memory holders) {
        return ticketHolders;
    }

    function getWinnerHistory() public view returns (address[] memory winners) {
        return winnerHistory;
    }

    function getRunnerHistory() public view returns (address[] memory runners) {
        return runnerHistory;
    }

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}