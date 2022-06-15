// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";

contract Course is ERC721 {

    string public name = "soheil vafaei - Solidity Course";// ERC721Metadata 

    string public symbol= "SOL"; // ERC721Metadata

    function ownerMint (string memory tokenUri_) public onlyOwner
    {
            _mint(_owner,mintCount);
            setTokenURI(mintCount,tokenUri_);
    }

    // Returns a URL that points to the metadata
    function tokenURI(uint256 tokenId) public view returns (string memory) { // ERC721Metadata
        require(_owners[tokenId] != address(0), "TokenId does not exist");
        return _tokenURIs[tokenId];
    }
    
    function supportsInterface(bytes4 interfaceId) public pure override returns(bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function totalSupply() public view returns (uint256) {
        return mintCount;
    }
}