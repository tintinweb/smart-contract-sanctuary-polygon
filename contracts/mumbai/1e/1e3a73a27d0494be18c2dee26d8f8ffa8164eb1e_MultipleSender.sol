/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract MultipleSender {
    address payable private owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function sendBNB(address payable[] memory recipients, uint256[] memory amounts) external payable {
        require(recipients.length == amounts.length, "Invalid input");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(amounts[i] > 0, "Amount must be greater than zero");
            recipients[i].transfer(amounts[i]);
        }
    }

    function withdraw() external {
        require(msg.sender == owner, "Only the contract owner can withdraw");
        owner.transfer(address(this).balance);
    }
}