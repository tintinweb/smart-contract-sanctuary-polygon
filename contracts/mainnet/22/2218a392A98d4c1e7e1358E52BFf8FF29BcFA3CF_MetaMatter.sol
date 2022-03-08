//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";

import './ERC2981Royalties.sol';


contract MetaMatter is ERC721, ERC721URIStorage, ERC2981Royalties, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using Strings for uint256;

    mapping (uint256 => string) private _tokenURIs;

    event MatterSelled(uint256 tokenId);

    string private _baseURIextended;

    Matter[] public matters;

    struct Matter {
        uint256 price;
        uint256 royalty;
        bool onSale;
        string tokenURI;
        address owner;
    }

    constructor() public ERC721("MetaMatter", "MATTER") {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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
        virtual
        override(ERC721, ERC2981Base, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mintNFT(address recipient, string memory tokenURI)
        public
        returns (uint256)
    {
        Matter memory _matter = Matter({
            price: 0,
            royalty: 0,
            onSale: false,
            tokenURI: tokenURI,
            owner: msg.sender
        });

        matters.push(_matter);

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        _tokenIds.increment();

        return newItemId;
    }

    function transactionNFT(address to, uint256 tokenId) external payable {
        address owner = address(uint160(ownerOf(tokenId)));
        require(owner != msg.sender);
        require(owner != address(0));

        Matter storage _matter = matters[tokenId];
        require(msg.value >= _matter.price);
        require(_matter.onSale == true);

        approve(to, tokenId);
        payable(owner).transfer(_matter.price);

        safeTransferFrom(owner, to, tokenId);
        _matter.price = 0;
        _matter.onSale = false;
        _matter.owner = to;
    }

    function sellNFT(address marketContract, uint256 tokenId, uint256 price) external {
        require(ownerOf(tokenId) == msg.sender);
        Matter storage _matter = matters[tokenId];
        _matter.price = price;
        _matter.onSale = true;

        setApprovalForAll(marketContract, true);

        emit MatterSelled(tokenId);
    }

    function setRoyalties(address to, uint256 tokenId, uint256 value) public {
        require(ownerOf(tokenId) == msg.sender);
        Matter storage _matter = matters[tokenId];
        _matter.royalty = value;
        _setRoyalties(to, value);
    }

    function getMatter(uint256 tokenId)
        public
        view
        returns (
            Matter memory _matter
        ) {
            Matter memory matter = matters[tokenId];
            return matter;
        }
}