/**
 *Submitted for verification at polygonscan.com on 2023-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StringValue {
    string private _myString;
    mapping(address => bool) private _allowedAddresses;
    address private _owner;

    modifier onlyAllowed() {
        require(_allowedAddresses[msg.sender], "Only allowed addresses can update the string value");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only contract owner can perform this operation");
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function getString() public view returns (string memory) {
        return _myString;
    }

    function setString(string memory newValue) external onlyAllowed {
        _myString = newValue;
    }

    function addAllowedAddress(address newAddress) external onlyOwner {
        _allowedAddresses[newAddress] = true;
    }

    function removeAllowedAddress(address addressToRemove) external onlyOwner {
        _allowedAddresses[addressToRemove] = false;
    }
}