/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract MaticSenderV3 {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
         if(msg.sender != owner) {
            revert("Sorry! You are not the owner");
        }
        _;
    }

    modifier NoBalance() {
        if(address(this).balance < 0) {
            revert("Sorry! Insufficient balance");
        }
        _;
    }

    function setOwner(address newOwner) public {
        owner = newOwner;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function inject() external payable {
        if(msg.sender != owner) {
            revert("Sorry the owner can not inject");
        }
        if(msg.value < 0.001 ether) {
            revert("Sorry! You need to inject 0.001 Matic or more");
        }
        

    }

    function withdrawal() external onlyOwner {
        if (address(this).balance < 0.001 ether) {
            revert("Sorry! Insufficient balance");
        }
        payable(msg.sender).transfer(0.001 ether);
    
    }


    function withdrawalAllToOwner() external onlyOwner NoBalance {
        uint256 balance = getBalance();
        payable(owner).transfer(balance);
    }

    function withdrawalHalf() external onlyOwner NoBalance {
        uint256 balance = getBalance() / 2;
        payable(msg.sender).transfer(balance);
    }
    
}