// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract UpdateTransaction {
    uint num;
    string Base64;

    constructor() {}

    event SetNumber(address _user, uint _number);
    event SetBase64(address _user, string _base64);

    function set(uint _num) public {
        num = _num;
        emit SetNumber(msg.sender, _num);
    }

    function setBase64(string memory _newBase64) public {
        Base64 = _newBase64;
        emit SetBase64(msg.sender, _newBase64);
    }

    function getBase64() public view returns (string memory) {
        return Base64;
    }

    function get() public view returns (uint) {
        return num;
    }
}