/*
This file is part of the MintMe project.

The MintMe Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The MintMe Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the MintMe Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/
// SPDX-License-Identifier: GNU lesser General Public License

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "Address.sol";
import "ReentrancyGuard.sol";
import "./imintmefactory.sol";


contract MintMe is ERC721, Ownable, ReentrancyGuard
{
    using Address for address payable;

    event ContentChanged(string contCID);
    event ContentChanged(uint256 indexed tokenId, string contCID);

    uint256                    private _counter;
    string                     private _base;
    IMintMeFactory             private _factory;
    string                     private _contentCID;
    string                     private _licenseCID;
    mapping(uint256 => string) private _contentCIDs;

    constructor(
            address       factory,
            string memory name,
            string memory symbol,
            string memory contCID,
            string memory licCID) ERC721(name, symbol)
    {
        _factory = IMintMeFactory(factory);
        _contentCID = contCID;
        _licenseCID = licCID;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "MintMe: URI query for nonexistent token");

        string memory baseURI = _factory.baseURI();
        string memory contCID = _contentCIDs[tokenId];
        return bytes(baseURI).length > 0 && bytes(contCID).length > 0 ?
            string(abi.encodePacked(baseURI, contCID)) : "";
    }

    function setContent(string memory contCID) public onlyOwner
    {
        _contentCID = contCID;
        _factory.onCollectionUpdated(contCID);
        emit ContentChanged(contCID);
    }

    function license() public view returns(string memory)
    {
        return _licenseCID;
    }

    function content() public view returns(string memory)
    {
        return _contentCID;
    }

    function setContent(uint256 tokenId, string memory contCID) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "MintMe: caller is not owner nor approved");
        _setContent(tokenId, contCID);
    }

    function _setContent(uint256 tokenId, string memory contCID) internal
    {
        _contentCIDs[tokenId] = contCID;
        _factory.onTokenUpdated(tokenId, contCID);
        emit ContentChanged(tokenId, contCID);
    }

    function content(uint256 tokenId) public view returns(string memory)
    {
        return _contentCIDs[tokenId];
    }

    function mint(address to, string memory contCID) public payable onlyOwner nonReentrant returns(uint256)
    {
        require(msg.value == _factory.feeWei(), "MintMe: insufficient funds");
        if (_factory.feeWei() != 0)
        {
            _factory.fundsReceiver().sendValue(_factory.feeWei());
        }
        _counter += 1;
        _mint(to, _counter);
        if (bytes(contCID).length != 0)
        {
            _setContent(_counter, contCID);
        }
        return _counter;
    }

    function safeMint(address to, string memory contCID) public payable nonReentrant onlyOwner returns(uint256)
    {
        require(msg.value == _factory.feeWei(), "MintMe: insufficient funds");
        if (_factory.feeWei() != 0)
        {
            _factory.fundsReceiver().sendValue(_factory.feeWei());
        }
        _counter += 1;
        _safeMint(to, _counter);
        if (bytes(contCID).length != 0)
        {
            _setContent(_counter, contCID);
        }
        return _counter;
    }

    function burn(uint256 tokenId) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "MintMe: caller is not owner nor approved");
        _burn(tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal override
    {
        super._transfer(from, to, tokenId);
        _factory.onTransfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal override
    {
        super._mint(to, tokenId);
        _factory.onTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal override
    {
        address owner = ERC721.ownerOf(tokenId);
        super._burn(tokenId);
        _factory.onTransfer(owner, address(0), tokenId);
    }

    function transferOwnership(address newOwner) public override onlyOwner
    {
        super.transferOwnership(newOwner);
        _factory.onCollectionTransfer(newOwner);
    }
}