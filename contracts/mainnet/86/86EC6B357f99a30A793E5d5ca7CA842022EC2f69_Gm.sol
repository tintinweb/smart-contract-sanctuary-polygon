// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Gm {
    event GmEvent(address indexed _from, bytes32 indexed _hash, uint _gmCount);
    mapping(bytes32 => bool) private nameExists;
    uint private gms;

    constructor() {
        gms = 0;
    }

    function getGms() public view returns (uint) {
        return gms;
    }

    function getCode() public pure returns (string memory) {
        return "0x0EdD3EE977bDdf18eAa3548eC8544B78c78F40e5";
    }

    function doGm(string memory name) public {
        require(bytes(name).length <= 100, "Input string too long");
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        require(!nameExists[nameHash], "Name already exists");
        nameExists[nameHash] = true;
        gms += 1;
        emit GmEvent(msg.sender, nameHash, gms);
    }
}