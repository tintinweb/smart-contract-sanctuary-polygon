/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestArray {

    address[] private _testArray;
    bytes private _encodeData;
    address[] private _decodeData;

    bytes private _enArrayData;
    address[] private _deArrayData;
    modifier checkArray {
        require(_testArray.length != 0);
        _;
    }

    function pushVal(address addr) public {
        _testArray.push(addr);
    }

    function popVal() public checkArray {
        _testArray.pop();
    }

    function deleteValByIndex(uint index) public checkArray {
        require(index < _testArray.length, "Index out of bounds!");
        if (_testArray.length - 1 == index) {
            _testArray.pop();
        } else {
            _testArray[index] = _testArray[_testArray.length-1];
            _testArray.pop();
        }
    }

    function showArray() public view returns(address[] memory, uint) {
        return (_testArray, _testArray.length);
    }

    function showEncodeData() public view returns(bytes memory) {
        return _encodeData;
    }

    function showDecodeData() public view returns(address[] memory) {
        return _decodeData;
    }

    function showEnArrayData() public view returns(bytes memory) {
        return _enArrayData;
    }

    function showDeArrayData() public view returns(address[] memory) {
        return _deArrayData;
    }

    function isEqualTest() public view returns(bool) {
        return (_decodeData.length == _testArray.length);
    }

    function encodeDefault() public {
         _encodeData = abi.encode(_testArray);
    }

    function decodeDefault() public {
        _decodeData = abi.decode(abi.encode(_testArray), (address[]));
    }

    function encodeArray(address[] memory addrArray) public {
        _enArrayData = abi.encode(addrArray);
    }

    function decodeArray(bytes memory encodedArrayData) public{
        _deArrayData = abi.decode(encodedArrayData, (address[]));
    }
}