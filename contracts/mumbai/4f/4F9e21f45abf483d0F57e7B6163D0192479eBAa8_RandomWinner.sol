// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract RandomWinner {

    mapping(address => uint256[]) _userTickets;
    address[] public tickets;
    uint256 public ticketPrice;
    uint256 deadLine;
    uint256 _winnerId;
    address _winner;

    constructor(uint256 _ticketPrice, uint256 _duration) {
        ticketPrice = _ticketPrice;
        deadLine = block.timestamp + _duration;
    }

    function winner() public view returns(address winner_, uint256 winnerId_) {
        winner_ = _winner;
        winnerId_ = _winnerId;
    }

    function userTickets(address userAddr) public view returns(uint256[] memory) {
        return _userTickets[userAddr];
    }

    function ticketCounter() public view returns(uint256) {
        return tickets.length;
    }

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function purchaseTicket() public payable {
        require(msg.value >= ticketPrice, "RandomWinner: insufficient fee");
        require(remainingTime() > 0, "RandomWinner: expired");
        _userTickets[msg.sender].push(tickets.length);
        tickets.push(msg.sender);
    }

    function remainingTime() public view returns(uint256) {
        return deadLine > block.timestamp ? deadLine - block.timestamp : 0;
    }

    function rollDice() public {
        require(remainingTime() == 0, "RandomWinner: The deadline has not yet arrived.");
        _winnerId = _randomness() % ticketCounter();
        _winner = tickets[_winnerId];
        payable(_winner).transfer(balance());
    }

    function _randomness() private view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao)));
    }
}