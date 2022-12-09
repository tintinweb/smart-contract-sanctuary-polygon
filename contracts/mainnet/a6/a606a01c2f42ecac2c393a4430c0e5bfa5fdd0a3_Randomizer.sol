/**
 *Submitted for verification at polygonscan.com on 2022-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IRandomizer {
    function getRandomMetaId() external returns (uint256);
}

contract Randomizer is IRandomizer {
    uint16[] public _buffer;
    uint16 public currentRandNum = 1;

    constructor(uint16 amount) {
        for(uint16 i = 0; i < amount; i ++) {
            _buffer.push(i);
        }
    }

    function getRandomMetaId() external override returns (uint256) {
        require(_buffer.length > 0, "No NFT exist");

        uint256 randIdx;
        uint256 randNum;
        
        randIdx = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, _buffer.length, currentRandNum))) % (_buffer.length);
        randNum = _buffer[randIdx];
        _buffer[randIdx] = _buffer[_buffer.length - 1];
        _buffer.pop();

        currentRandNum = uint16(randNum + 1);

        return currentRandNum; //random number
    }

    function getBufferLength() public view returns (uint256) {
        return _buffer.length;
    }
}