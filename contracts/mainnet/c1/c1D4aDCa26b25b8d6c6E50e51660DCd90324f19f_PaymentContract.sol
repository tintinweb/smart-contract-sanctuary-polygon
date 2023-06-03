/**
 *Submitted for verification at polygonscan.com on 2023-06-03
*/

/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PaymentContract {
    address payable public owner;
    address public daiTokenAddress = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;

    event PaymentReceived(address payer, uint256 amount);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    function boosting() public payable returns (bool) {
        require(msg.value > 1, "GlobalPower: invalid amount");
        owner.transfer(msg.value);
        return true;
    }

    function withdrawFunds() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}