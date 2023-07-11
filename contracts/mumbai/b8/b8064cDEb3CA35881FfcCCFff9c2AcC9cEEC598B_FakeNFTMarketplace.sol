//SPDX_License-Identifier:MIT

pragma solidity ^0.8.18;


contract FakeNFTMarketplace {

    uint256 constant public NFT_PRICE = 0.1 ether;

    mapping(uint256 => address) public tokens;

    function purchase(uint256 _tokenId) external payable{
        require(msg.value == NFT_PRICE, "This NFT costs 0.1 ether");
        tokens[_tokenId] = msg.sender;
    }

    function getPrice() external pure returns(uint256){
        return NFT_PRICE;
    }

    /// @dev available() checks whether the given tokenId has already been sold or not
    /// @param _tokenId - the tokenId to check for
    function available(uint256 _tokenId) external view returns(bool) {
        // address(0) = 0x0000000000000000000000000000000000000000
        // This is the default value for addresses in Solidity
        if(tokens[_tokenId] == address(0))
         return true;
    return false;
        
    }
}