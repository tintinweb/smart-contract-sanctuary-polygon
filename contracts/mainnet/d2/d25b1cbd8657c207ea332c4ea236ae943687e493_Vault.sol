// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Vault {
    event Deposit(address, uint256);
    uint256 public number = 0;
    address public owner = address(0);

    function increment() public {
        number++;
    }

    function setOwner(address newOwner) public {
        require(owner == address(0), "Owner already set"); // only allow set owner once.
        owner = newOwner;
    }

    function withdraw(uint256 amount) public {
        require(owner != address(0), "Owner not set");
        require(number % 3 == 2, "Invalid number");
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}