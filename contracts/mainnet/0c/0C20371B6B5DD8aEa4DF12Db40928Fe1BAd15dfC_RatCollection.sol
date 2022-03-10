// SPDX-License-Identifier: GNU lesser General Public License
//
// Hate Race is a daily race of the most vile and ugly rats that
// parasitize on society. Our rats have nothing to do with animals,
// they are the offspring of the sewers of human passions.
//
// If you enjoy it, donate our hateteam ETH/MATIC/BNB:
// 0xd065AC4Aa521b64B1458ACa92C28642eB7278dD0

pragma solidity ^0.8.0;

import "./ratfactory.sol";

contract RatCollection is Ownable, ERC721, IERC721Receiver
{
    RatFactory public _factoryContract;
    address    public _boss;
    string     public _base;

    constructor(address factoryContract, address boss) ERC721("Hate Race", "Collection")
    {
        _factoryContract = RatFactory(factoryContract);
        _boss = boss;
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

    function setBossAddress(address boss) public onlyOwner
    {
	require(boss != address(0), "RatCollection: zero address");
        _boss = boss;
    }

    function onERC721Received(address /*operator*/, address /*from*/, uint256 tokenId, bytes calldata /*data*/) public override returns (bytes4)
    {
        require(_msgSender() == address(_factoryContract), "RatCollection: unknown contract");
        _safeMint(_boss, tokenId);
        return this.onERC721Received.selector;
    }

    function withdraw(uint256 tokenId) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "RatCollection: transfer caller is not owner nor approved");
        _factoryContract.safeTransferFrom(address(this), _msgSender(), tokenId);
        _burn(tokenId);
    }
}