/**
 *Submitted for verification at polygonscan.com on 2022-11-20
*/

pragma solidity >=0.7.0 <0.9.0;

contract randomNumber {

    uint8 public number;

    function store() public {
        number = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.number)))%251);
    }
    }