// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract TestNFT2 is ERC721, Ownable {
    using Strings for uint256;

    uint public constant MAX_TOKENS = 100000;
    uint private constant TOKENS_RESERVED = 100;
    uint public price = 1000000000000000;
    uint256 public constant MAX_MINT_PER_TX = 100;

    bool public isSaleActive;
    uint256 public totalSupply;
    mapping(address => uint256) private mintedPerWallet;

    string public baseUri;
    string public baseExtension = ".json";

    constructor() ERC721("Test NFT 2", "TNFT2") {
        baseUri = "ipfs://bafybeihvhjaua2kphpit3rorn4jwqqquc6hmwquua6hygz4nmixlimxn3q/";
        for(uint256 i = 1; i <= TOKENS_RESERVED; ++i) {
            _safeMint(msg.sender, i);
        }
        totalSupply = TOKENS_RESERVED;
    }

    // Public Functions
    function mint(uint256 _numTokens) external payable {
        require(isSaleActive, "The sale is paused.");
        require(_numTokens <= MAX_MINT_PER_TX, "You cannot mint that many in one transaction.");
        require(mintedPerWallet[msg.sender] + _numTokens <= MAX_MINT_PER_TX, "You cannot mint that many total.");
        uint256 curTotalSupply = totalSupply;
        require(curTotalSupply + _numTokens <= MAX_TOKENS, "Exceeds total supply.");
        require(_numTokens * price <= msg.value, "Insufficient funds.");

        for(uint256 i = 1; i <= _numTokens; ++i) {
            _safeMint(msg.sender, curTotalSupply + i);
        }
        mintedPerWallet[msg.sender] += _numTokens;
        totalSupply += _numTokens;
    }

    // Owner-only functions
    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 balanceOne = balance * 70 / 100;
        uint256 balanceTwo = balance * 30 / 100;
        ( bool transferOne, ) = payable(0x8a32E1C5BaAAE72E8BAb2872B83747AdFa5F63CE).call{value: balanceOne}("");
        ( bool transferTwo, ) = payable(0x8a32E1C5BaAAE72E8BAb2872B83747AdFa5F63CE).call{value: balanceTwo}("");
        require(transferOne && transferTwo, "Transfer failed.");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
 
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }
 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}