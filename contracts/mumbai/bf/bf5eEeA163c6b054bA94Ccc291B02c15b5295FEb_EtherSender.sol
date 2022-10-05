/**
 *Submitted for verification at polygonscan.com on 2022-10-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract EtherSender {
    address payable owner = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);

    function send() external payable {
    }
 
    function withdrawFixedAmount() external {
        address payable sender = payable(msg.sender); // memory

        sender.transfer(0.01 ether);
    }

    function withdrawHalfBalance() external {
        uint256 halfBalanceAmount = getBalance() / 2;
        address payable sender = payable(msg.sender);

        sender.transfer(halfBalanceAmount);
    }

    function withdrawOwner() external {
        uint256 balance = getBalance();

        owner.transfer(balance);
    }

    function getBalance() private view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }
}