// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Greeter {

    address payable public owner;
    string public greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
        owner = payable(msg.sender);
    }

    function greet(string memory _name) view public returns (string memory) {
        return string.concat(greeting, _name, "!");
    }

    function updateGreeting(string memory _newGreeting) public payable {
        require(msg.value >= 1 ether, "You should pay at least 1 ETH do update the greeting");

        owner.transfer(msg.value);

        greeting = _newGreeting;
    }
}