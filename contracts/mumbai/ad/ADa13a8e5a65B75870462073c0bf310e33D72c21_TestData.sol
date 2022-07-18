// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TestData {

    mapping(address=>string) public descriptions;
    mapping(address=>string) public names;
    
    function updateName(address adr,string memory val) public {
        names[adr] = val;
    }

    function updateDesc(address adr, string memory val) public {
        descriptions[adr] = val;
    }
}