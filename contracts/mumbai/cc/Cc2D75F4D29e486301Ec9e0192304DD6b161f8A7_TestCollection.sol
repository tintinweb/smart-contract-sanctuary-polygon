// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract TestCollection {
    address payable public owner;

    event Withdrawal(uint amount, uint when);
    event AmountReceived(uint amount);

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable virtual {
        emit AmountReceived(msg.value);
    }

    function withdraw() public {
        require(msg.sender == owner, "You aren't the owner");
        emit Withdrawal(address(this).balance, block.timestamp);
        owner.transfer(address(this).balance);
    }
}