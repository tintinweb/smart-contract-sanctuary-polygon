// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WordVault {

    function readWord() external view returns(string memory) {
        return "Enclosure";
    }

}