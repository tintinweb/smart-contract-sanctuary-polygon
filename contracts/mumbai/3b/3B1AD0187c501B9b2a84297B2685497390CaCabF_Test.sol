// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Test {

    address a;

    constructor(address vrfCoordinator) {
        a = vrfCoordinator;
    }

    function test1() public pure returns (uint256) {
        return 1;
    }
    function test2() public pure returns (uint256) {
        return 1;
    }
    uint256 public fee;
    // ID of public key against which randomness is generated
    bytes32 public keyHash;


}