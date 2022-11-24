// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Test {

    address a;
    address b;

    constructor(address vrfCoordinator, address linkToken) {
        a = vrfCoordinator;
        b = linkToken;
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