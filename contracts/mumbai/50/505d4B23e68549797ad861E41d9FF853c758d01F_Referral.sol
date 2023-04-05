// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Referral {
    uint256 amount;

    event Bet(address bettor, address referrer, uint256 amount);
    constructor() {
    }

    function placeBet(address _referrer, uint256 _amount) public {
        amount += _amount;
        emit Bet(msg.sender, _referrer, _amount);
    }
}