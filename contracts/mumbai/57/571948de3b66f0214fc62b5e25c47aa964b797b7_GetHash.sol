/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract GetHash {

event LiveCheck(address User);

function getHash(string calldata _text) public pure returns (bytes32){
    return keccak256(bytes(_text));
}

function justEmit() public {
    emit LiveCheck(msg.sender);
}

}