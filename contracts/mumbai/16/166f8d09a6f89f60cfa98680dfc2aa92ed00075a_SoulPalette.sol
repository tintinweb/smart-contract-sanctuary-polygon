/**
 *Submitted for verification at polygonscan.com on 2023-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract SoulPalette {
    struct Entry {
        string[4] colors;
        string[4] comments;
        string[4] stamps;
        int8 happiness;
        uint256 timestamp;
    }
    
    mapping(address => Entry[]) public entries;

    function addEntry(string[4] memory colors, string[4] memory comments, string[4] memory stamps, int8 happiness, uint256 timestamp) public {
        Entry memory newEntry = Entry(colors, comments, stamps, happiness, timestamp);
        entries[msg.sender].push(newEntry);
    }

    function getEntries(address user, uint256 startTimestamp, uint256 endTimestamp) public view returns (Entry[] memory) {
        uint256 count = 0; // count 変数を最初に定義する
        for (uint256 i = 0; i < entries[user].length; i++) {
            Entry memory entry = entries[user][i];
            if (entry.timestamp >= startTimestamp && entry.timestamp <= endTimestamp) {
                count++; // エントリーが条件を満たす場合に count をインクリメントする
            }
        }

        Entry[] memory selectedEntries = new Entry[](count); // count を使用して selectedEntries 配列を初期化する
        count = 0; // count をリセットする

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