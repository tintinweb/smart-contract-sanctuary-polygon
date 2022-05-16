// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract HelloWorld
{
    string _greeting;
    address _ownerAddress;

    constructor(string memory greeting)
    {
        _greeting = greeting;
        _ownerAddress = msg.sender;
    }

    modifier onlyOwner()
    {
        require(msg.sender == _ownerAddress, "Try again!");
        _;
    }

    function sayHello() public view returns (string memory)
    {
        return _greeting;
    }

    function changeGreeting(string memory greeting) public onlyOwner()
    {
        _greeting = greeting;
    }
}