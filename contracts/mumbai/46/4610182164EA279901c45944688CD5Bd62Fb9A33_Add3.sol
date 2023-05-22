/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

contract Add3 {

    uint256 ourNumber;

    function initialize() public {
        ourNumber = 0x64;
    }

    function getNumber() public view returns (uint256) {
        return ourNumber;
    }

    function addThree() public {
        ourNumber = ourNumber + 3;
    }

}


//  "e2fbc880": "addThree()",
//     "f2c9ecd8": "getNumber()",
//     "8129fc1c": "initialize()"