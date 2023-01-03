// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.11;

contract Index {

    address owner;

    mapping (string => address) addressBook;

    constructor() {
        owner = msg.sender;    
    }

    function whoOwnsThis() public view returns (address) {
        return owner;
    }

    function getAddress(string memory key) public view returns (address) {
        return addressBook[key];
    }

    function setAddress(string calldata key, address _value) external {
        addressBook[key] = _value;
    }
}