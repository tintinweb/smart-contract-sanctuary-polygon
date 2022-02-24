/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./VCMock.sol";

contract VAMock is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    bytes3[16] private palette;

    mapping(uint256 => address) private _fixedAdr;
    mapping(uint256 => bool) private _fixDone;
    mapping(uint256 => bool) private _projectToken;
    mapping(uint256 => string) private _skinOf;

    event TokenCreated(uint256 indexed tokenId, string created);
    event TokenSkinApplied(uint256 indexed tokenId, string covered);
    event TokenURISet(uint256 indexed tokenId, string uri);
    event TokenFixedAdr(uint256 indexed tokenId, string fix);

    modifier projectTokens() {
        if (_tokenId.current() < 40) {
            require(msg.sender == owner(), "First 40 tokens are for VAMock.");
            _projectToken[_tokenId.current() + 1] = true;
        }
        _;
    }

    modifier checkOwner(uint256 tokenId) {
        require(
            ownerOf(tokenId) == msg.sender,
            "Caller must be the token owner."
        );
        _;
    }

    modifier checkString(string memory _string) {
        require(
            bytes(_string).length != 0,
            "The string argument can't be empty."
        );
        _;
    }

    constructor() ERC721("VAMock", "vamock") {}

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function vamockToken() external payable projectTokens returns (uint256) {
        _tokenId.increment();
        uint256 tokenId = _tokenId.current();
        _safeMint(msg.sender, tokenId);
        string memory created = "token created!";
        emit TokenCreated(tokenId, created);
        return tokenId;
    }

    function setSkinOf(uint256 tokenId, string memory skinURL)
        external
        checkOwner(tokenId)
        checkString(skinURL)
        returns (bool)
    {
        _skinOf[tokenId] = skinURL;
        string memory covered = "token skin cover applied!";
        emit TokenSkinApplied(tokenId, covered);
        return true;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        external
        checkOwner(tokenId)
        checkString(_tokenURI)
        returns (bool)
    {
        _setTokenURI(tokenId, _tokenURI);
        string memory uri = "token URI set!";
        emit TokenURISet(tokenId, uri);
        return true;
    }

    function fixAdr(uint256 tokenId, address adr)
        external
        checkOwner(tokenId)
        returns (bool)
    {
        require(_projectToken[tokenId], "Only valid for first 40 tokens.");
        require(!_fixDone[tokenId], "The address is already fixed.");
        _fixedAdr[tokenId] = adr;
        _fixDone[tokenId] = true;
        string memory fix = "token address data fixed!";
        emit TokenFixedAdr(tokenId, fix);
        return true;
    }

    function getDataOn(uint256 tokenId)
        external
        view
        returns (address, bytes3[40] memory)
    {
        address adr;
        if (_projectToken[tokenId] && _fixDone[tokenId]) {
            adr = _fixedAdr[tokenId];
        } else {
            adr = ownerOf(tokenId);
        }
        bytes3[40] memory colors = VCMock.getColors(adr, palette);
        return (adr, colors);
    }

    function getSkinOf(uint256 tokenId) external view returns (string memory) {
        return _skinOf[tokenId];
    }

    function getDataOff(address _adr)
        external
        view
        returns (address, bytes3[40] memory)
    {
        address adr = _adr;
        bytes3[40] memory colors = VCMock.getColors(adr, palette);
        return (adr, colors);
    }

    function getPalette() external view returns (bytes3[16] memory) {
        return palette;
    }

    function _setPalette(bytes3[16] memory _palette) private {
        for (uint256 i = 0; i <= 15; i++) {
            palette[i] = _palette[i];
        }
    }
}