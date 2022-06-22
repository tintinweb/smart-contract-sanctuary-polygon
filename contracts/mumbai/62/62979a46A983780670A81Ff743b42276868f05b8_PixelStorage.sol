/**
 *Submitted for verification at polygonscan.com on 2022-06-21
*/

pragma solidity ^0.8.15;

contract PixelStorage {

    uint256 _territory;
    bytes[] _pixeldata;

    constructor () {
    }

    function setPixelData(bytes[] memory _data) public {
        _pixeldata = _data;
    }

    function getPixelData() public view returns (bytes[] memory) {
        return _pixeldata;
    }
}