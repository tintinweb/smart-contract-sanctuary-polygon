/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SplitContract {
    address public wallet1;
    address public wallet2;
    uint256 public percentage1;
    uint256 public percentage2;

    modifier onlyAuthorized() {
        require(msg.sender == wallet1 || msg.sender == wallet2, "Only authorized wallets can call this function");
        _;
    }

    constructor(address _wallet1, address _wallet2, uint256 _percentage1, uint256 _percentage2) {
        require(_percentage1 + _percentage2 == 100, "Percentages must add up to 100");
        wallet1 = _wallet1;
        wallet2 = _wallet2;
        percentage1 = _percentage1;
        percentage2 = _percentage2;
    }

    function distribute() external onlyAuthorized {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to distribute");

        uint256 amount1 = (balance * percentage1) / 100;
        uint256 amount2 = balance - amount1;

        (bool success1, ) = payable(wallet1).call{value: amount1}("");
        require(success1, "Transfer to wallet1 failed");

        (bool success2, ) = payable(wallet2).call{value: amount2}("");
        require(success2, "Transfer to wallet2 failed");
    }

    receive() external payable {}
}