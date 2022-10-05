/**
 *Submitted for verification at polygonscan.com on 2022-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract GreinSender {
    address owner = 0x49fA62108dE1A881DfB36fFFABa6093BAf7f1622;

    function send() external payable returns(uint256) {
        return msg.value;
    }

    function withdraw() external {
        address payable to = payable(msg.sender);
        uint amount = 0.01 ether;
        to.transfer(amount);
    } 

    function withdrawHalf() external {
        address payable to = payable(msg.sender);
        uint amount = getBalance() / 2;
        to.transfer(amount);
    }

    function withdrawOwner() external {
        address payable to = payable(getOwner());
        uint amount = getBalance();
        to.transfer(amount);
    } 

    function getBalance() private view returns(uint256){
        uint balance = address(this).balance;
        return balance;
    }

    function getOwner() private view returns (address) {
        return owner;
    }
    
}