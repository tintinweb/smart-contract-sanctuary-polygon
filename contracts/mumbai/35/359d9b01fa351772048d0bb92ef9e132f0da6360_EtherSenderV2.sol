/**
 *Submitted for verification at polygonscan.com on 2022-10-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract EtherSenderV2 {
    address public owner;
    uint256 minDeposit = 0.02 ether;

    constructor() {
        owner = msg.sender;
    }

    function depositMoney() external payable {
         uint256 amount = msg.value;

         if (amount < minDeposit) {
         revert("Error, minimum deposit should be at least 0.02 matic");
        }
    }
   
    function sendMoney() external {   
        address payable to = payable(msg.sender);
        uint256 amount = (0.002 ether);
        to.transfer(amount);

        if (getBalance() <= 0.002 ether) {
        revert("Error, not enough balance available");
        }
    }

    function withdrawAll() external {
        address payable to = payable(msg.sender);
        uint ownerOnly = address(this).balance;
        to.transfer(ownerOnly);

        if (owner != msg.sender) {
        revert("Top secret, you require clearance level 5 to do this");
        }
    }

    function getBalance() internal view returns (uint) {
        uint balance = address(this).balance;
        return balance;
    }
}