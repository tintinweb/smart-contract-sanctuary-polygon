/**
 *Submitted for verification at polygonscan.com on 2022-08-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Hashing {
    bytes32 public hashed;

    function setHash() public returns (bool hashPassed){
        hashed = keccak256(abi.encodePacked(address(msg.sender)));
        return (hashed == 0 ? false : true);
    }

    function getHash() public view returns (bytes32 hashedVal){
        return hashed;
    }

}