/**
 *Submitted for verification at polygonscan.com on 2022-07-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test {
    
    function getOwner() external pure returns (string memory) {
        return "hi";
    }

    // function callOwner() public pure {
    //     getOwner();
    // }

    mapping(string => uint256) public count;
    uint256 public value;

    function addMapping(string calldata key, uint256 val) public {
        count[key] = val;
    }

    function increaseCount1(string calldata key) public {
        value = ++count[key];
    }

    function increaseCount2(string calldata key) public {
        value = count[key]++;
    }

}