/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract NameStore {
    string[] public names;

    function getNames() external view returns (string[] memory) {
        return names;
    }

    function pushToName(string memory _name) external {
        names.push(_name);
    }

    function remove(uint index) external {
        require(index <= names.length, "");

        for (uint i = index; i < names.length-1; i++){
            names[i] = names[i+1];
        }
        
        names.pop();
    }
}