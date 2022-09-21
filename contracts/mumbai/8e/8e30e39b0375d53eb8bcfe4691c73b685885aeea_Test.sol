/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test {

    event Encode(bytes);
    event Decode(uint256, uint256);
        event EncodePacked(bytes);
    event DecodePacked(uint256, uint256);

    function encode(uint256 id, uint256 id2) public returns(bytes memory) {
        bytes memory encoded = abi.encode(id, id2);
        emit Encode(encoded);
        return encoded;
    }

     function decode(bytes memory encoded) public returns(uint256,uint256) {
         (uint256 id, uint256 id2) = abi.decode(encoded, (uint256, uint256));
         emit Decode(id, id2);
        return (id, id2);
    }

    function encodePacked(uint256 id, uint256 id2) public returns(bytes memory) {
        bytes memory encoded = abi.encodePacked(id, id2);
        emit EncodePacked(encoded);
        return encoded;
    }
}