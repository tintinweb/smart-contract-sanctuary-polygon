/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

contract NameRecorder {
    string name;

    constructor(string memory _newName){
        name = _newName;
    }

    function setName(string memory _newName) external {
        name = _newName;
    }

    function getName() external view returns(string memory) {
        return name;
    }
}