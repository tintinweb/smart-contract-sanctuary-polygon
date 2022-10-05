/**
 *Submitted for verification at polygonscan.com on 2022-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract EtherSender {
    address owner = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    
    function send() external payable {
    
    }

    function getBalance() public view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

    function withdrawToOwner() external {
        address payable to = payable(owner);
        uint256 amount = getBalance();
        to.transfer(amount);
    }
    
    function getSomeMatic() external {
        address payable to = payable(msg.sender);
        to.transfer(0.01 ether);
    }
    
    function getHalfBalance() external {
        address payable to = payable(msg.sender);
        uint256 amount = getBalance();
        to.transfer(amount / 2);
    }
}