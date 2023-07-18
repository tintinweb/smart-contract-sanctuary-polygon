// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// contract address: 0x636A290EbC9b8a9ccC9bA6f32789624EE4c9dfa5
contract FakeNFTMarketplace {
    // maintain mapping of Fake TokenID to owner addresses
    mapping(uint256 => address) public tokens;

    // set purchase price for each Fake NFT
    uint256 nftPrice = 0.01 ether;

    // purchase() accepts ETH and marks owner of the given tokenId as caller address
    // _tokenId - fake NFT token Id to purchase
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT costs 0.01 ether");
        tokens[_tokenId] = msg.sender;
    }

    // getPrice() returns price of 1 NFT
    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    // available() checks whether given tokenId has already been sold or not
    // _tokenId - tokenId to check for
    function available(uint256 _tokenId) external view returns (bool) {
        // default address(0) = 0x0000000000000000000000000000000000000000
        // default value for addresses in Solidity
        if (tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }
}