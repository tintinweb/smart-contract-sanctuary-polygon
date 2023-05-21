// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Box {
    uint public val;
    string public ownerName;

    struct User {
        string name;
        uint value;
    }
    mapping(address => User) public users ;

    function inc() external {
        val += 1;
    }

    function setName(string memory _name) external {
        ownerName = _name;
    }

    function createUser(string memory _name , uint _value) external{
        users[msg.sender] = User(_name , _value);
    }

}