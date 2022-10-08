/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Voting {
    uint public candidate1 = 0;
    uint public candidate2 = 0;

    function voteForCandidate1() public {
        candidate1++;
    }

    function voteForCandidate2() public {
        candidate2++;
    }
}