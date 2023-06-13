/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AddressToStringMapping {
    mapping(address => string) private addressToString;

    function getString() public view returns (string memory) {
        return addressToString[msg.sender];
    }

    function setString(string memory newString) public {
        addressToString[msg.sender] = newString;
    }
}