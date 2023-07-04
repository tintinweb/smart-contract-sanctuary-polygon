// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

contract CREATE3Factory {
    function deploy(bytes32 salt, bytes memory creationCode)
        external
        payable
        returns (address)
    {
        address deployed = msg.sender;
        return deployed;
    }

}