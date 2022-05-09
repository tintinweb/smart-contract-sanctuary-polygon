/**
 *Submitted for verification at polygonscan.com on 2022-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract Test {
    
    mapping(address => uint256) public testMap;

    function writeToMap(address[] calldata addresses_, uint256[] calldata numbers_) public {
        for(uint256 i = 0; i < addresses_.length; i++) {
            testMap[addresses_[i]] = numbers_[i];
        }
    }

}