/**
 *Submitted for verification at polygonscan.com on 2023-01-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract NameStore {
    string[] public names;

    function getNames() public view returns (string[] memory) {
        return names;
    }

    function pushToName(string memory _name) public {
        names.push(_name);
    }
}