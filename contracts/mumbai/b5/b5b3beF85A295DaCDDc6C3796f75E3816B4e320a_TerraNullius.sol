// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TerraNullius {
    struct Claim {
        address claimant;
        string message;
        uint blockNumber;
    }

    Claim[] public claims;

    function claim(string calldata message) public {
        claims.push(Claim(msg.sender, message, block.number));
    }
}