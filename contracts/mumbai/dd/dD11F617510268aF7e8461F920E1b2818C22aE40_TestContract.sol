/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TestContract {
    string pingResponse = "ping";
    int256 count = 0;

    function PrefixPing(string memory prefix, int256 random) public view returns (string memory) {
        return string.concat(prefix, pingResponse);
    }

    function Ping() public view returns (string memory) {
        return pingResponse;
    }

    function Count() public returns (int256) {
        count++;
        return count;
    }
}