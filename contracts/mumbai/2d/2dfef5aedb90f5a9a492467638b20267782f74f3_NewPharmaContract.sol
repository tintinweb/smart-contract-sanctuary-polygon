/**
 *Submitted for verification at polygonscan.com on 2022-08-30
*/

// SPDX-License-Identifier: None
pragma solidity >=0.8.9;

contract NewPharmaContract {
   string public message;

    constructor() {
      message = "NEWPHARMA INIT";
    }

    function getMessage() public view returns(string memory) {
        return message;
    }
}