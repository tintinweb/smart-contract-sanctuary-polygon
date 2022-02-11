//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Canvas {
    uint32[100000][100000] public pixels;
    uint64 public width;
    uint64 public height;
    uint256 public changeCount = 0;
    address public owner;

    constructor(uint64 _width, uint64 _height) {
        width = _width;
        height = _height;
        owner = msg.sender;
    }

    function getPixelLine(uint32 i)
        public
        view
        returns (uint32[100000] memory)
    {
        return pixels[i];
    }

    function draw(uint64[] calldata _pixels) public {
        changeCount++;
        for (uint8 i = 0; i < _pixels.length; i++) {
            pixels[(_pixels[i] / 100000000) / 100000][
                (_pixels[i] / 100000000) % 100000
            ] = uint32(_pixels[i] % 100000000);
        }
    }
}