/**
 *Submitted for verification at polygonscan.com on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract ExerciseClass2 {

    // declaration and assignment of state variables
    uint maxTotalSuply = 500;
    address adres = msg.sender;

    // function input new max total suply (state variable / storage)
    function setMaxTotalSuply(uint newMax) external {
        maxTotalSuply = newMax;
    }

    // function output max total suply (local variable / memory)
    function getMaxTotalSuply() external view returns(uint) {
        return maxTotalSuply;
    }

    // function output owner,s address (global variable / storage)
    function getOwner() external view returns(address) {
        return adres;
    }

    // function output token,s info (local variable / memory)
    function getTokenInfo() external pure returns (string memory) {
        string memory tokenInfo = "Peringolo coin  (PLC)";
        return tokenInfo;
    }
}