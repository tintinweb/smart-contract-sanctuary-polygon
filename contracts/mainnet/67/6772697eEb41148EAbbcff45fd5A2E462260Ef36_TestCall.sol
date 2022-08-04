/**
 *Submitted for verification at polygonscan.com on 2022-08-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract NFTNYCSwags { // This doesn't have to match the real contract name. Call it what you like.
    //function f1(bool arg1, uint arg2) returns(uint); // No implementation, just the function signature. This is just so Solidity can work out how to call it.
    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual;
}

contract TestCall {

    address contractAddress = 0x1AC8a6bAC2f5Bd8207C15FCF94AA68004f157129;
    address burnAddress = 0xD36B5cF4af949B8Fb680e9746245ED46A1B07bB6;
    uint tokenId = 3770219340782527833965313;

    function transfer() public {
        address tokenOwner = msg.sender;
        NFTNYCSwags nftnyc = NFTNYCSwags(contractAddress);
        nftnyc.safeTransferFrom(tokenOwner, burnAddress, tokenId);
    }

}