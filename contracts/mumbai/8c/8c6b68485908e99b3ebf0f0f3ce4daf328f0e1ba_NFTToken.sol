// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721URIStorage.sol";
import "Pausable.sol";
import "Ownable.sol";
import "ERC721Burnable.sol";
import "draft-EIP712.sol";
import "draft-ERC721Votes.sol";
import "Counters.sol";

contract NFTToken is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable, EIP712, ERC721Votes {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public baseURI;

    address public childChainManagerProxy;
    // limit batching of tokens due to gas limit restrictions
    uint256 public constant BATCH_LIMIT = 20;
    event WithdrawnBatch(address indexed user, uint256[] tokenIds);

    constructor() ERC721("TEST NFT", "TNF") EIP712("TEST NFT", "1") {
        baseURI = "https://nft-test.ttogttog.com/";
        childChainManagerProxy = 0xb5505a6d998549090530911180f38aC5130101c6;
    }

    function updateChildChainManager(address _childChainManager) public onlyOwner() {
        childChainManagerProxy = _childChainManager;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner() {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function safeMassMint(address[] memory _address, string[] memory _uris) public onlyOwner {
        require(_address.length == _uris.length, "array length must be the same");

        for(uint i = 0 ; i < _address.length; i++) {
            safeMint(_address[i], _uris[i]);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Votes)
    {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function deposit(address user, bytes calldata depositData)
        external
    {
        require(msg.sender == childChainManagerProxy, "You're not allowed to deposit");

        // deposit single
        if (depositData.length == 32) {
            uint256 tokenId = abi.decode(depositData, (uint256));
            _mint(user, tokenId);

        // deposit batch
        } else {
            uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
            uint256 length = tokenIds.length;
            for (uint256 i; i < length; i++) {
                _mint(user, tokenIds[i]);
            }
        }
    }

    function withdraw(uint256 tokenId) external {
        require(_msgSender() == ownerOf(tokenId), "ChildERC721: INVALID_TOKEN_OWNER");
        _burn(tokenId);
    }

    function withdrawBatch(uint256[] calldata tokenIds) external {
        uint256 length = tokenIds.length;
        require(length <= BATCH_LIMIT, "ChildERC721: EXCEEDS_BATCH_LIMIT");
        for (uint256 i; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_msgSender() == ownerOf(tokenId), string(abi.encodePacked("ChildERC721: INVALID_TOKEN_OWNER ", tokenId)));
            _burn(tokenId);
        }
        emit WithdrawnBatch(_msgSender(), tokenIds);
    }
}