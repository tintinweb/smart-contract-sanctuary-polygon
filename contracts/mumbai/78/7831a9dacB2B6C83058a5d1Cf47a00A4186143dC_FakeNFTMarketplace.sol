// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract FakeNFTMarketplace {
    mapping(uint256 => address) public tokens;
    uint256 nftPrice = 0.1 ether;

    //will purchase nft
    function purchase(uint256 _tokenId) external payable {
        require(msg.value >= nftPrice, "This NFT is priced at 0.1 ethers");
        //assign the tokenId to the user
        tokens[_tokenId] = msg.sender;
    }

    //get the price of NFT
    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    //check if NFT Available
    function available(uint256 _tokenId) external view returns (bool) {
        if (tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }
}