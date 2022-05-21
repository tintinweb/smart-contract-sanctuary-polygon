/**
 *Submitted for verification at polygonscan.com on 2022-05-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract Escrow {
    enum State { AWAITING_PAYMENT, AWAITING_DELIVERY}
    
    State public currState;
    
    address public buyer;
    address payable public seller;
    address public owner;
    
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this method");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this method");
        _;
    }
    
    constructor(address _buyer, address payable _seller) {
        buyer = _buyer;
        seller = _seller;
    }
    
    function deposit() onlyBuyer external payable {
        require(currState == State.AWAITING_PAYMENT, "Already paid");
        currState = State.AWAITING_DELIVERY;
    }
    
    function confirmDelivery() onlyBuyer external {
        require(currState == State.AWAITING_DELIVERY, "Cannot confirm delivery");
        seller.transfer(address(this).balance);
        currState = State.AWAITING_PAYMENT;
    }
}