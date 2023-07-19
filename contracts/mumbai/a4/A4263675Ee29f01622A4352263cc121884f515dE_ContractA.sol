// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract ContractA {
    string public name;

    function updateName(string memory _name) public returns (string memory) {
        name = _name;
        return name;
    }
}