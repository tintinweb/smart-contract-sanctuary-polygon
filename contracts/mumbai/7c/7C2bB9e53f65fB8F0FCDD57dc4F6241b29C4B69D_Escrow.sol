/**
 *Submitted for verification at polygonscan.com on 2022-06-13
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

contract Escrow{

    address payable public buyer;
    address payable public seller;

    enum State{
        AWAITING_PAYMENT,
        AWAITING_DELIVERY,
        COMPLETE
    }

    State public projectState;

    constructor(address payable _buyer, address payable _seller){
        buyer = _buyer;
        seller = _seller;
    }

    function deposit() public payable {
        require(msg.sender == buyer, "Only the buyer can deposit ETH here!");
        projectState = State.AWAITING_DELIVERY;

    }

    function lockedAmount() public view returns(uint256){
        return address(this).balance;
    }

    function confirmDelivery() public {
        require(msg.sender == buyer, "Only the buyer can release the locked funds!");
        seller.transfer(address(this).balance);
        projectState = State.COMPLETE;
    }
    
}