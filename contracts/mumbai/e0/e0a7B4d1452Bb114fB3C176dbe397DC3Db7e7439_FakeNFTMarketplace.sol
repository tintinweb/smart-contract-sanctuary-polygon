// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract FakeNFTMarketplace {
    /// @dev Maintain a mapping of Fake TokenId to Owner address
    mapping(uint256 => address) public tokens;

    /// @dev Set the Purchase price for each Fake NFT
    uint256 nftPrice = 0.0001 ether;

    /// @dev purchase() accepts ETH and marks the owner of the given tokenId as the caller address
    /// @param _tokenId - the fake NFT tokenId to purchase
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT cost 0.0001 ether");
        tokens[_tokenId] = msg.sender;
    }

    /// @dev getPrice() returns the price of one NFT
    function getPricer() external view returns (uint256) {
        return nftPrice;
    }

    /// @dev available() checks wheter the given tokenId has alreade been sold or not
    /// @param _tokenId - the tokenId to check for
    function available(uint256 _tokenId) external view returns (bool) {
        // address(0) = 0x00000
        // This is the default value for address in Solidity
        if (tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }
}