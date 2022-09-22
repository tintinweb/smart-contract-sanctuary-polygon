/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract ExerciseClass2 {

    // declaration and assignment of variables
    uint maxTotalSuply = 500;
    string nameToken = "Peringolo coin";
    string symbolToken = "PLC";

    // function input new max total suply
    function setMaxTotalSuply(uint newMax) external {
        maxTotalSuply = newMax;
    }

    // function output max total suply
    function getMaxTotalSuply() external view returns(uint) {
        return maxTotalSuply;
    }

    // function output owner,s address
    function getOwner() external view returns(address) {
        return msg.sender;
    }

    // function output token,s info
    function getTokenInfo() external view returns(string memory, string memory) {
        return (nameToken, symbolToken);
    }
}