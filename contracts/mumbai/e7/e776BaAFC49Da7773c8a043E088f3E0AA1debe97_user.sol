// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract user{
     mapping (address => string) public users;

    constructor(address _addr, string memory _stringValue) {
        users[_addr] = _stringValue;
    }

        function getUsername(address _addr) public view returns(string memory){
            if(bytes(users[_addr]).length > 0){
                return users[_addr];
            }
            return "Usernotfound";
        }

    function addAddressString(address _addr, string memory _stringValue) public {
        users[_addr] = _stringValue;
    }
}