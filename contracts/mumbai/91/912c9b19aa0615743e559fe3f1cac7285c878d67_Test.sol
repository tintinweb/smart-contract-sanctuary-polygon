/**
 *Submitted for verification at polygonscan.com on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test {
    string greeting;

    function get() public view returns (string memory) {
        return greeting;
    }
    
    function set(string calldata _greeting) public {
        greeting = _greeting;
    }
    
}