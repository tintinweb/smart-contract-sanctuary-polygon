// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SocialNFT is ERC721Enumerable, Ownable {
    uint public tokensMinted = 0;
    mapping(uint256 => string) public socialTokenURI;
    mapping(uint256 => string) public metaURI;

    constructor() ERC721("SocialNFT", "SNFT") {
    }

    function mintNFT(address recipient, string memory _tokenURI, string memory _metaURI) 
        public onlyOwner returns(uint256) {
            tokensMinted ++;
            _mint(recipient, tokensMinted);
            socialTokenURI[tokensMinted] = _tokenURI;
            metaURI[tokensMinted] = _metaURI;
            return tokensMinted;
    }
}