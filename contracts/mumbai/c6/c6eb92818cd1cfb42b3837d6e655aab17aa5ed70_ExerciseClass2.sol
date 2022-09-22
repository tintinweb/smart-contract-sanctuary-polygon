/**
 *Submitted for verification at polygonscan.com on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract ExerciseClass2 {

    // declaration and assignment of state variable
    uint maxTotalSuply = 500;

    // function input new max total suply (state variable / storage)
    function setMaxTotalSuply(uint newMax) external {
        maxTotalSuply = newMax;
    }

    // function output max total suply (local variable / memory)
    function getMaxTotalSuply() external view returns(uint) {
        return maxTotalSuply;
    }

    // function output owner,s address (local variable / memory)
    function getOwner() external view returns(address) {
        return msg.sender;
    }

    // function output token,s info (local variable / memory)
    function getTokenInfo() external pure returns (string memory) {
        string memory tokenInfo = "Peringolo coin  (PLC)";
        return tokenInfo;
    }
}