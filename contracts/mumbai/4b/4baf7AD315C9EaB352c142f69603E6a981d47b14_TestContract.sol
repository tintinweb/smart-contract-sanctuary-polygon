// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TestContract {
    uint256 public autoIncrement;
    
    event Test(uint256 indexed id);
    
    function emitTest() public {
        autoIncrement++;
        emit Test(autoIncrement);
    }
}