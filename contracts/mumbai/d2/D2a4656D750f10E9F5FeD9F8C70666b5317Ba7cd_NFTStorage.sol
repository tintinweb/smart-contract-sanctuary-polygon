/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

contract NFTStorage{

    uint256 public maxSupply;

    bytes32 public constant MINTER = keccak256("MINTER");

    bytes32 public constant OWNER = keccak256("OWNER");


    mapping (uint256 => string) public _tokenURIs;


}