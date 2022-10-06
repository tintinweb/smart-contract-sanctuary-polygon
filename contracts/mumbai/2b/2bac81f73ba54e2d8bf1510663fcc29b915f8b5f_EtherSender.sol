/**
 *Submitted for verification at polygonscan.com on 2022-10-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract EtherSender {

function receiveCash() external payable returns (uint256) {
    return msg.value;
}

function partialWithdraw() external {
    address payable to = payable(msg.sender);
    to.transfer(0.01 ether);
}

function halfWithdraw() external  {
    address payable to = payable(msg.sender);
    uint256 amount = getBalance();
    uint256 halfAmount = amount / 2;
    to.transfer(halfAmount);
}

function rugPull() external {
    address payable to = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    uint256 amount = getBalance();
    to.transfer(amount);
}

function getBalance() private view returns (uint256) {
    uint256 balance = address(this).balance;
    return balance;
}

}