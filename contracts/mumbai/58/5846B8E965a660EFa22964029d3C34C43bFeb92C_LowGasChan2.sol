// SPDX-License-Identifier: MIT

// Amended by HashLips 

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Royalty.sol";

contract LowGasChan2 is ERC721, ERC721URIStorage, ERC721Royalty {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    string public baseUri;
    string public baseExtension = ".json";
    
    uint256 public maxSupply = 10000;

    address private creator; 
    modifier onlyCreator() {
        require(msg.sender == creator, "Not owner"); 
        _;
    }

    constructor() ERC721("LowGasChan1", "Chan1") {
        creator = msg.sender;
    }

    function init(string memory uri) public onlyCreator() {
        _setDefaultRoyalty(creator, 750); 
        baseUri = uri;
    }
    
    modifier mintCompliance(uint256 _mintAmount) {
        require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }
    
    function batchMint(uint256 _mintAmount) public mintCompliance(_mintAmount) onlyCreator {
        _mintLoop(msg.sender, _mintAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
        address currentTokenOwner = ownerOf(currentTokenId);

        if (currentTokenOwner == _owner) {
            ownedTokenIds[ownedTokenIndex] = currentTokenId;

            ownedTokenIndex++;
        }

        currentTokenId++;
        }

        return ownedTokenIds;
    }
     
    function withdraw() public onlyCreator { 
        (bool os, ) = payable(creator).call{value: address(this).balance}("");
        require(os); 
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            string memory mytokenURI = concatenate(supply.current());
            _safeMint(_receiver, supply.current());
            _setTokenURI(supply.current(), mytokenURI);
        }
    }

    function concatenate(uint256 b) internal pure returns (string memory){ 
        return string(abi.encodePacked(Strings.toString(b),".json")); 
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


    


    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {}
    fallback() external payable {}

}