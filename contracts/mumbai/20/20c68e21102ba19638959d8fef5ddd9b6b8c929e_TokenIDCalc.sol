/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract TokenIDCalc {
    function getTokenID(uint256 tierID) public pure returns (uint256) {
        return (2**128) * tierID;
    }
}