/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Voting {

    // Voter counter
    uint public candidate1 = 0;
    uint public candidate2 = 0;

    // Store voters address for each candidate
    address[] public voters1;
    address[] public voters2;

    // Vote for candidate 1
    function voteForCandidate1() public {
        candidate1++; // increament counter
        voters1.push(msg.sender); // push voters address to array
    }

    // Vote for candidate 2
    function voteForCandidate2() public {
        candidate2++; // increament counter
        voters1.push(msg.sender); // push voters address to array
    }
}