/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract SoulPalette {
    struct Entry {
        string[4] colors;
        string[4] comments;
        int8 happiness;
        uint256 timestamp;
    }
    
    mapping(address => Entry[]) public entries;

    function addEntry(string[4] memory colors, string[4] memory comments, int8 happiness, uint256 timestamp) public {
        Entry memory newEntry = Entry(colors, comments, happiness, timestamp);
        entries[msg.sender].push(newEntry);
    }

    function getEntries(address user, uint256 startTimestamp, uint256 endTimestamp) public view returns (Entry[] memory) {
        Entry[] memory selectedEntries;
        uint256 count = 0;
        for (uint256 i = 0; i < entries[user].length; i++) {
            Entry memory entry = entries[user][i];
            if (entry.timestamp >= startTimestamp && entry.timestamp <= endTimestamp) {
                selectedEntries[count] = entry;
                count++;
            }
        }
        return selectedEntries;
    }
}