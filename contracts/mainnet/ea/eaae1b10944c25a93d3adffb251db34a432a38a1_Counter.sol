/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    mapping(address => uint256) private _counts;

    function seventhspaceGetCurrentCount(address countOf) public view returns (uint256) {
        return _counts[countOf];
    }

    function seventhspaceIncrementCount() public {
        _counts[msg.sender] += 1;
    }

    function seventhspaceCurrentCount(address countOf) public view returns (uint256) {
        return _counts[countOf];
    }
}