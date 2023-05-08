// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    uint256 totalCoffee;
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    event NewCoffee (
        address indexed from,
        uint256 timestamp,
        string message,
        string name
    );

    struct Coffee {
        address sender;
        string message;
        string name;
        uint256 timestamp;
    }

    Coffee[] coffee;

    function getAllCoffee() public view returns (Coffee[] memory) {
        return coffee;
    }    

    function getTotalCoffee() public view returns (uint256) {
        return totalCoffee;
    }

    function buyCoffee(
        string memory _message,
        string memory _name
    ) payable public {
        require(msg.value == 0.01 ether, "You need to pay 0.01 ETH");

        totalCoffee += 1;
        coffee.push(Coffee(msg.sender, _message, _name, block.timestamp));

        (bool success,) = owner.call{value: msg.value}("");
        require(success, "Failed to send Ether to owner");

        emit NewCoffee(msg.sender, block.timestamp, _message, _name);
    }
}