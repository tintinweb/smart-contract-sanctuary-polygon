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

contract RatPutin is Ownable, ERC721
{
    event SkinCreated(uint256 indexed skinId, uint256 indexed ratId, string hash);

    struct Skin
    {
        uint256 ratId;
        string  hash;
    }
    mapping (uint256 => Skin) public  _skins;
    string                    public  _base;
    address                   public  _boss;

    constructor () ERC721("Hate Race", "Putin")
    {
        setBaseURI("https://haterace.com/putin/");
	_boss = address(0x2a31947412692Bfe94C9D57ba9D74b36C22A9BC4);
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        _base = baseURI;
    }

    function _baseURI() internal view override returns (string memory)
    {
        return _base;
    }

    function setBossAddress(address boss) public onlyOwner
    {
        _boss = boss;
    }

    function createSkin(uint256 ratId, uint256 skinId, string memory hash) public onlyOwner returns(uint256)
    {
        _safeMint(_boss == address(0) ? _msgSender() : _boss, skinId);
        _skins[skinId].ratId = ratId;
        _skins[skinId].hash = hash;
        emit SkinCreated(skinId, ratId, hash);
        return skinId;
    }
}