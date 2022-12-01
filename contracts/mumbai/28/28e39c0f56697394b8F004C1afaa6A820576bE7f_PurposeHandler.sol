/**
 *Submitted for verification at polygonscan.com on 2022-11-30
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract PurposeHandler {
    string public purpose = "Building Unstoppable Apps!!!";

    constructor() {

    }

    function setPurpose(string memory newPurpose) public {
        purpose = newPurpose;
    }
}