/**
 *Submitted for verification at polygonscan.com on 2022-07-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract PixelArt {
    uint constant private _MAP_SIZE = 879999;
    mapping(uint => string) private _pixels;
    mapping(address => uint) private _lastColorize;

    constructor() {
        for (uint id = 0; id < 100; id++) {
            _pixels[id] = "0f0f0f0";
        }


    }

    function colorizePixel(uint _id, string memory _color) external {
        require(bytes(_color).length == 6, "ERROR: Not correct color");
        require(_id <= _MAP_SIZE, "ERROR: Not correct pixel id");
        require(block.timestamp >= _lastColorize[msg.sender] + 5 minutes);
        _pixels[_id] = _color;
    }

    function getPixel(uint _id) public view returns(string memory) {
        return _pixels[_id];
    }

    function getAllPixels() public view returns(string[] memory) {
        string[] memory colorsArray = new string[](_MAP_SIZE);
        for (uint id = 0; id < _MAP_SIZE; id++) {
            colorsArray[id] = _pixels[id];
        }
        return colorsArray;
    }

    function getAllPixelsFromId(uint _startPixel, uint _count) public view returns(string[] memory) {
        string[] memory colorsArray = new string[](_count);
        for (uint id = 0; id < _count; id++) {
            colorsArray[id] = _pixels[_startPixel + id];
        }
        return colorsArray;
    }
}