/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestArray {

    address[] private testArray;

    modifier checkArray {
        require(testArray.length != 0);
        _;
    }

    function pushVal(address addr) public {
        testArray.push(addr);
    }

    function popVal() public checkArray {
        testArray.pop();
    }

    function deleteValByIndex(uint index) public checkArray {
        require(index < testArray.length, "Index out of bounds!");
        if (testArray.length - 1 == index) {
            testArray.pop();
        } else {
            testArray[index] = testArray[testArray.length-1];
            testArray.pop();
        }
    }

    function showArray() public view returns(address[] memory, uint) {
        return (testArray, testArray.length);
    }

    function encode() public returns (bytes memory) {
        return abi.encode(testArray);
    }

    function decodeDefault() public returns (address[] memory) {
        return abi.decode(abi.encode(testArray), (address[]));
    }

    function decode(bytes memory encodedData) public returns (address[] memory) {
        return abi.decode(encodedData, (address[]));
    }

    function encodeArray(address[] memory addrArray) public  returns (bytes memory) {
        return abi.encode(addrArray);
    }

    function decodeArray(bytes memory encodedArrayData) public returns (address[] memory) {
        return abi.decode(encodedArrayData, (address[]));
    }
}