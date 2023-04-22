/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.18;

interface IMyContract {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract WithdrawContract {
    address public myContractAddress = 0xa4FBacAD097f0cB650cEF69255E306292263c93B;
    address payable public owner;
    uint256 public amount;

    constructor() {
        owner = payable(msg.sender);
    }

    function withdraw() external {
        IMyContract myContract = IMyContract(myContractAddress);
        amount = myContract.balanceOf(address(this));
        myContract.transfer(owner, amount);
    }
}