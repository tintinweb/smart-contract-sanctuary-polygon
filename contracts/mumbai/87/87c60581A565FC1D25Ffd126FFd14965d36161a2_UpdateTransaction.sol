// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract UpdateTransaction {
    string Base64;
    uint256 blockNumber;

    constructor() {}

    event SetBase64(address _user, uint256 __blockNumber, string _base64);

    function setBase64(uint256 _blockNumber, string memory _newBase64) public {
        Base64 = _newBase64;
        blockNumber = _blockNumber;
        emit SetBase64(msg.sender, _blockNumber, _newBase64);
    }

    function getBase64() public view returns (string memory) {
        return Base64;
    }
}