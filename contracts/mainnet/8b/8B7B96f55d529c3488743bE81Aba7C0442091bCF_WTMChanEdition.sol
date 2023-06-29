// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol"; 
import "./Counters.sol";
import "./ERC721Royalty.sol";


contract WTMChanEdition is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Royalty {
    using Counters for Counters.Counter;
    Counters.Counter private idCounter;
     
    uint256 private maxSupply = 10000;
    
    string public baseUri;
    string public baseExtension = ".json";

    address private creator; 
    modifier onlyCreator() {
        require(msg.sender == creator, "Not owner"); 
        _;
    }
 
    receive() external payable {}
    fallback() external payable {}

    constructor() ERC721("WTM - Chan Edition", "WTM") { 
        creator = msg.sender;
    }
    
    function init(string memory _uri) public onlyCreator {
        baseUri = _uri; 
        _setDefaultRoyalty(creator, 750);
        idCounter.increment(); 
    }
    function batchMint(uint256 amount) external onlyCreator {
        require(idCounter.current() + amount <= maxSupply, "Exceeded maximum supply");
        
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = idCounter.current();
            idCounter.increment();

            string memory mytokenURI = _concatenate(tokenId);
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, mytokenURI);
        }
    }

    function _concatenate(uint256 b) internal pure returns (string memory){ 
        return string(abi.encodePacked(Strings.toString(b),".json")); 
    }

    function getNumber()  public view returns(uint256) {
        return idCounter.current();
    }
       
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function uint256ToString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        
        uint256 temp = value;
        uint256 digits;
        
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
 
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, uint256ToString(tokenId), baseExtension))
            : "";
    }
 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
    function setBaseUri(string memory _baseUri) external onlyCreator {
        baseUri = _baseUri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, ERC721Royalty, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}