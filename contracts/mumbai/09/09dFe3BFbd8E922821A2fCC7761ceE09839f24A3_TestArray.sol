/**
 *Submitted for verification at polygonscan.com on 2022-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestArray {

    address[] private _testArray;
    bytes private _encodeData;
    address[] private _decodeData;
    bytes private _enExternalData;
    address[] private _deExternalData;

    modifier checkArray {
        require(_testArray.length != 0);
        _;
    }

    function ArrayInit(address[] memory array) public {
        _testArray = array;
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

    function encodeDefault() public {
        _encodeData = abi.encode(_testArray);
    }

    function decodeDefault() public {
        _decodeData = abi.decode(abi.encode(_testArray), (address[]));
    }

    function enExternal(address[] memory addrArray) public {
        _enExternalData = abi.encode(addrArray);
    }

    function deExternal(bytes memory encodedArrayData) public{
        _deExternalData = abi.decode(encodedArrayData, (address[]));
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

    function showEnData() public view returns(bytes memory) {
        return _enExternalData;
    }

    function showDeData() public view returns(address[] memory) {
        return _deExternalData;
    }

    function isEqualTest() public view returns(bool) {
        return (_decodeData.length == _testArray.length);
    }
}