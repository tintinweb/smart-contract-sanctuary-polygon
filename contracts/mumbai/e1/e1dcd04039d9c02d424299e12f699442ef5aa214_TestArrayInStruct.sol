/**
 *Submitted for verification at polygonscan.com on 2022-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract TestArrayInStruct {

    struct MyStruct {
        uint256 n;
        uint256[] arr;
    }
    
    mapping(uint256 => MyStruct) public myMapping;

    function setMyMapping(uint256 key, uint256 n, uint256 c) external {
        MyStruct storage m = myMapping[key];
        m.n = n;
        m.arr = new uint256[](c);
        for (uint256 i = 0; i < c; ++i)
            m.arr[i] = i+1;
    }

    function getMyStruct(uint256 key) external view returns (MyStruct memory) {
        return myMapping[key];
    }

    function getMyStruct2(uint256 key, uint256 n) external view returns (MyStruct memory, uint256) {
        return (myMapping[key], n);
    }

    function getMappingArr(uint256 key) external view returns (uint256[] memory) {
        return myMapping[key].arr;
    }
}