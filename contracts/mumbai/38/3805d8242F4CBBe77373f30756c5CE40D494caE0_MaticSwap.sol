/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MaticSwap {
    mapping(address => uint256) balances;
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    // 1eth = 1 IG coin

    function buyToken() external payable {
        require( msg.value >= 1 gwei , "Amount is not equal to 1 gwei");
        balances[msg.sender] += msg.value / 1 gwei;
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getBalance(address _of) external view returns (uint256) {
        return balances[_of];
    }

    function redeem() external payable {
        require(msg.sender == owner, "Only Owner can redeem the Balance");

        owner.transfer(contractBalance());
    }
}