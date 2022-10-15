/**
 *Submitted for verification at polygonscan.com on 2022-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SeaCryptEggHatched {

    constructor() { }

    function onERC721Received(
        address, 
        address, 
        uint256, 
        bytes calldata
    ) external returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 
}