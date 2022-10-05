/**
 *Submitted for verification at polygonscan.com on 2022-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract EtherSender {
    address owner = 0x23E579fD443f3723a2b2840eb7b101B0B8a0964e;
    
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

// Practice smart contract from lesson n3 with Berenu.