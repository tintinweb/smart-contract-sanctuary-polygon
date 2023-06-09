/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract NFTFundsTransfer {
    mapping(uint256 => address) public tokenOwners;
    address public fixedWallet = 0xc89b8a6a114da47E3eFeC972D7dc2d94E8F131fe;
    address public nftContract = 0x849547b1e08b0E0A7898C2274113c09F7A76b78d;
    
    function setTokenOwner(uint256 tokenID, address owner) external {
        require(msg.sender == nftContract, "Only the NFT contract can set token owners.");
        tokenOwners[1] = owner;
    }
    
    function transferFunds(uint256 tokenId) external {
        require(tokenOwners[1] != address(0), "Token owner not set");
        
        address tokenOwner = tokenOwners[1];
        payable(fixedWallet).transfer(address(tokenOwner).balance);
    }
}