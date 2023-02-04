/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IERC721 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getApproved(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ICBY {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
// Marketplace Contract
contract Marketplace {
    // ERC721 Token Contract instance
    IERC721 private nft;
    ICBY private cby;
    // Mapping from token id to its price
    mapping(uint256 => uint256) private tokenPrices;
    // Save listed token ids
    uint256 []listed;
    // Event to track the sale of an NFT
    event Sale(address indexed from, uint256 tokenId, uint256 price);
    // Constructor to initialize the ERC721 Token Contract instance
    constructor(address _nft, address _cby) {
        nft = IERC721(_nft);
        cby = ICBY(_cby);
    }
    // Function to list an NFT for sale
    function listNFTforSale(uint256 tokenId, uint256 price) external {
        require(nft.ownerOf(tokenId) == msg.sender, "Only the owner can list an NFT for sale");
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)) == true, "Please approve the NFT to Marketplace contract");
        tokenPrices[tokenId] = price;
        listed.push(tokenId);
    }
    function priceOf(uint256 tokenId) external view returns(uint256) {
        return tokenPrices[tokenId];
    }
    function getListedNFTs() external view returns(uint256[] memory) {
        return listed;
    }
    // Function to buy an NFT
    function buyNFT(uint256 tokenId) external {
        require(tokenPrices[tokenId] > 0, "Token is not for sale"); 
        require(tokenPrices[tokenId] <= cby.balanceOf(msg.sender), "Insufficient $CBY"); 
        require(tokenPrices[tokenId] <= cby.allowance(msg.sender, address(this)), "$CBY allowed to marketplace is not sufficient"); 
        address seller = nft.ownerOf(tokenId); 
        require(seller != address(0), "Token does not exist"); 
        cby.transferFrom(msg.sender, seller, tokenPrices[tokenId]);
        nft.transferFrom(seller, msg.sender, tokenId);
        tokenPrices[tokenId] = 0; 
        for(uint256 i=0; i<listed.length; i++) {
            if(listed[i] == tokenId) {
                listed[i] = listed[listed.length-1];
                listed.pop();
                break;
            }
        }
    }
}