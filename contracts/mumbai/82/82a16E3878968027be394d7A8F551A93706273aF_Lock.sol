// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    address public owner;
    event Deposit(address indexed depositor, uint256 amount);
    event Withdraw(address indexed depositor, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        require(msg.value > 0, "!BALANCE");
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable {
        require(msg.value > 0, "!BALANCE");
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address to, uint256 amount) external {
        require(msg.sender == owner, "!OWNER");
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Failed to send balance");
    }
}