/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract ExerciseClass2 {

    uint maxTotalSuply = 500;
    address owner = msg.sender;
    string nameToken = "Peringolo coin";
    string symbolToken = "PLC";

    function setMaxTotalSuply(uint newMax) external {
        maxTotalSuply = newMax;
    }

    function getMaxTotalSuply() external view returns(uint) {
        return maxTotalSuply;
    }

    function getOwner() external view returns(address) {
        return owner;
    }

    function getTokenInfo() external view returns(string memory, string memory) {
        return (nameToken, symbolToken);
    }
}