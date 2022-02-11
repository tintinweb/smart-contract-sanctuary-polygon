// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./CROCROW.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC2981PerTokenRoyalties.sol";
import "./Context.sol";
import "./Counters.sol";

contract CROWPUNK is
    Context,
    Ownable,
    ERC721Enumerable,
    ERC2981PerTokenRoyalties
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    
    bool public tokenURIFrozen = false;
    string private baseTokenURI;
    uint256 public max = 3000;

    address public punkAddress = 0x1039600f4D73fb30e08C569e1096109bab1fd514;
    address public crowAddress = 0x336Eb339e7BBC420F8Ea388EB34C4fd2BE17b8A6;
    ERC721 private punks;
    CROCROW private crows;

    mapping(uint256 => bool) private crowUsed;

    constructor(
        string memory name,
        string memory symbol,
        string memory uri
    ) ERC721(name, symbol) {
        baseTokenURI = uri;
        _tokenIdTracker.increment();
        punks = ERC721(punkAddress);
        crows = CROCROW(crowAddress);
    }
    
    function mint(uint256 id1, uint256 id2) public {
        require(!crowUsed[id1], "Crow 1 already used");
        require(_msgSender() == crows.ownerOf(id1), "Crow 1 not owned");
        crowUsed[id1] = true;
        require(!crowUsed[id2], "Crow 2 already used");
        require(_msgSender() == crows.ownerOf(id2), "Crow 2 not owned");
        crowUsed[id2] = true;
        require(punks.balanceOf(_msgSender()) > 0, "Need to own at least one Punk");
        require(_tokenIdTracker.current() <= max, "Collection max size has been reached");
        _safeMint(_msgSender(), _tokenIdTracker.current());
        _setTokenRoyalty(_tokenIdTracker.current(), owner(), 700);
        _tokenIdTracker.increment();
    }

    function updateRoyalty(uint256 id, address recipient, uint256 amount) public onlyOwner{
        _setTokenRoyalty(id, recipient, amount);
    }
    
    function setBaseTokenURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        baseTokenURI = uri;
    }
    
    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function isCrowUsed(uint256 tokenId) public view returns (bool) {
        require(0 < tokenId && tokenId < max, "Token out of range");
        return crowUsed[tokenId];
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function availableCrows(address _owner) public view returns (uint256[] memory, bool[] memory) {
        uint256 ownerTokenCount = crows.balanceOf(_owner);
        uint256[] memory tokenIds = crows.walletOfOwner(_owner);
        bool[] memory availableArray = new bool[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            availableArray[i] = crowUsed[tokenIds[i]];
        }
        return (tokenIds, availableArray);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981PerTokenRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}