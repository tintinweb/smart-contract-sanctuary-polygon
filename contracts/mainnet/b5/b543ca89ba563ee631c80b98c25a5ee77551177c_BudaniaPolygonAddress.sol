/**
 *Submitted for verification at polygonscan.com on 2023-02-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract BudaniaPolygonAddress {
    mapping (address => address) public virtualAddresses;

    function createVirtualAddress() public {
        bytes32 hash = keccak256(abi.encodePacked(now, msg.sender));
        address newVirtualAddress = address(bytes20(hash));
        virtualAddresses[msg.sender] = newVirtualAddress;
    }

    function getVirtualAddress() public view returns (address) {
        return virtualAddresses[msg.sender];
    }
}