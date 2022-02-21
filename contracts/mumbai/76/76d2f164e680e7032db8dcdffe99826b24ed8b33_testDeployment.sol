/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract testDeployment {

    address owner;

    constructor() {
        owner = msg.sender;
    }

    function changeOwner(address _owner) public {
        require( msg.sender == owner, "Only owner can assign new owner" );
        owner = _owner;
    }

}