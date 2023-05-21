// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Box2 {
    uint public val;
    string ownerName;

    struct User {
        string name;
        uint value;
    }
    mapping(address => User) public users ;

    struct Admin{
        string adminName;
        uint numberPhone;
    }

    mapping(string => Admin) public admins;

    function addAdmin(string memory _name , uint _numberPhone) public {
        admins[_name] = Admin(_name , _numberPhone);
        
    }

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