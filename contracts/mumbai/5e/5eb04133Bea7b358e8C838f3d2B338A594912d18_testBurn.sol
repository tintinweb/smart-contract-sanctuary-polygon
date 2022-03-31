/**
 *Submitted for verification at polygonscan.com on 2022-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract testBurn{
    
    address offseter;
    uint256 value;
    uint256 balance;
    uint256 offset_amount;
    event HasBurnt(address offseter, uint256 amount, uint256 time);
    

    constructor() {
        offseter = msg.sender;
    }

    // receive amount of token from the caller
    function receiveFund() public payable {
        balance += msg.value;
    }

    // get current balance in the contract
    function getBalance() public view returns(uint256) {
        return balance;
    }

    function getTime() public view returns(uint256) {
        return block.timestamp;
    }

    function getOffseter() public view returns(address) {
        return msg.sender;
    }

    // burn all balance in the contract
    function burn() public payable {
        address payable _to = payable(address(0));

        // get current balance in contract, reday for burn
        offset_amount = getBalance();

        // burn and make sure token has burnt
        (bool burnt, ) = _to.call{value: offset_amount}("");
        require(burnt, "Failed to burn tokens");

        // emit event to record the burnt status
        emit HasBurnt(offseter, offset_amount, getTime());
        
        // renew the balance
        balance = address(this).balance;
    }

}