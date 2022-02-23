// SPDX-License-Identifier: GNU lesser General Public License
//
// Hate Race is a daily race of the most vile and ugly rats that
// parasitize on society. Our rats have nothing to do with animals,
// they are the offspring of the sewers of human passions.
//
// If you enjoy it, donate our hateteam ETH/MATIC/BNB:
// 0xd065AC4Aa521b64B1458ACa92C28642eB7278dD0

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";

contract RatSkins is Ownable, ERC721
{
    event SkinCreated(uint256 indexed skinId, uint256 indexed ratId, string hash);

    struct Skin
    {
        uint256 ratId;
        string  hash;
    }
    mapping (uint256 => Skin) public  _skins;
    string                    public  _base;
    uint256                   private _skinsCounter;

    constructor () ERC721("Hate Race", "Skins")
    {
        setBaseURI("https://haterace.com/skins/");
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        _base = baseURI;
    }

    function _baseURI() internal view override returns (string memory)
    {
        return _base;
    }
    
    function createSkin(uint256 ratId, string memory hash) public onlyOwner returns(uint256)
    {
        _skinsCounter += 1;
        _safeMint(_msgSender(), _skinsCounter);
        _skins[_skinsCounter].ratId = ratId;
        _skins[_skinsCounter].hash = hash;
        emit SkinCreated(_skinsCounter, ratId, hash);
        return _skinsCounter;
    }
}