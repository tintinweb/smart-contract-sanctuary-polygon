/**
 *Submitted for verification at polygonscan.com on 2022-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract GreinCalls {
    address owner = 0x49fA62108dE1A881DfB36fFFABa6093BAf7f1622;

    function send() external payable returns(uint256) {
        require(msg.value >= 0.02 ether, "error: you need to send at least 0,02 eth");
        return msg.value;
    }

    function withdraw() external {
        address payable to = payable(msg.sender);
        uint amount = 0.01 ether;
        require(getBalance() >= amount, "error: not enought balance");
        to.transfer(amount);
    } 

    function withdrawHalf() external {
        address payable to = payable(msg.sender);
        require(getBalance() > 0, "error: the sc has no balance");
        uint amount = getBalance() / 2;
        to.transfer(amount);
    }

    function withdrawOwner() external {
        address ownerSC = getOwner();
        require(ownerSC == msg.sender, "error: you are not the owner");
        require(getBalance() > 0, "error: the sc has no balance");
        address payable to = payable(ownerSC);
        uint amount = getBalance();
        to.transfer(amount);
    } 

    function getBalance() private view returns(uint256) {
        uint balance = address(this).balance;
        return balance;
    }

    function getOwner() private view returns (address) {
        return owner;
    }
}