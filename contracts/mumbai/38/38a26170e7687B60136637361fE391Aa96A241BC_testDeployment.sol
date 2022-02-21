/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract testDeployment {

    address owner;
    uint256 a;

    constructor(uint256 _a) {
        a = _a; 
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        require( msg.sender == owner, "Only owner can assign new owner" );
        owner = _owner;
    }

}