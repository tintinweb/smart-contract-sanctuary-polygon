/**
 *Submitted for verification at polygonscan.com on 2022-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract Ticket {

    uint public ticketPrice = 0.00005 ether;
    uint public maxItemsPerTx = 10;
    address public recipient;
    address public owner;

    event LogPurchase(address indexed owner, string email, uint amount);

    constructor(address _recipient) {
        recipient = _recipient;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function buyTicket(string memory email, uint amount) external payable {
        require(amount <= maxItemsPerTx, "exceeded max items");
        require(msg.value == amount * ticketPrice, "need more eth");
        emit LogPurchase(msg.sender, email, amount);
    }

    function setTicketPrice(uint _ticketPrice) external onlyOwner {
        ticketPrice = _ticketPrice;
    }

    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }
    
    // WITHDRAWAL FUNCTIONALITY

    /**
     * @dev Withdraw the contract balance to the recipient address
     */
    function withdraw() external onlyOwner {
        uint amount = address(this).balance;
        (bool success,) = recipient.call{value: amount}("");
        require(success, "failed to send ether");
    }
}