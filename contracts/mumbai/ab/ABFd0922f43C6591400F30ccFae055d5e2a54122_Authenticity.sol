// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Authenticity {
    error ArrayLengthMismatch();

    mapping(address => mapping(bytes32 => bool)) private _hashMap;

    constructor() {}

    function writeHash(bytes32[] memory hash_) external {
        for (uint256 i; i < hash_.length; i++) {
            _hashMap[msg.sender][hash_[i]] = true;
        }
    }

    function readHash(
        address[] calldata address_,
        bytes32[] calldata hash_
    ) external view returns (bool[] memory) {
        if (address_.length != hash_.length) revert ArrayLengthMismatch();

        bool[] memory result = new bool[](hash_.length);
        for (uint256 i; i < hash_.length; i++) {
            result[i] = _hashMap[address_[i]][hash_[i]];
        }
        return result;
    }
}