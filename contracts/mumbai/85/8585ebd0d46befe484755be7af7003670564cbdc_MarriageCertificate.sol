/**
 *Submitted for verification at polygonscan.com on 2023-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MarriageCertificate {

    // Define a struct to represent a marriage certificate
    struct Marriage {
        address issuer;
        string spouse1;
        string spouse2;
        uint256 timestamp;
        bool isMarried;
    }

    // Map the marriage certificate to the couple's Ethereum addresses
    mapping(address => mapping(address => Marriage)) public marriages;

    // Create a marriage certificate for the given Ethereum addresses
    function createMarriage(address spouse1, address spouse2, string memory name1, string memory name2) public {
        require(spouse1 != spouse2, "Spouses' addresses must be different.");
        require(!marriages[spouse1][spouse2].isMarried, "Marriage already exists.");
        
        marriages[spouse1][spouse2] = Marriage({
            issuer: msg.sender,
            spouse1: name1,
            spouse2: name2,
            timestamp: block.timestamp,
            isMarried: true
        });

        // Symmetric mapping
        marriages[spouse2][spouse1] = marriages[spouse1][spouse2];
    }

    // Check if the given Ethereum addresses are married
    function isMarried(address spouse1, address spouse2) public view returns(bool) {
        return marriages[spouse1][spouse2].isMarried;
    }
}