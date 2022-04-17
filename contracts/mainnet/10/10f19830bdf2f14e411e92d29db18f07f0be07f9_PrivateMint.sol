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

import "./mintme.sol";
import "./imintmefactory.sol";


contract PrivateMint is Ownable
{
    using Address for address payable;

    event RequestReceived(address to, string contCID);
    event RequestRejected(string contCID);
    event RequestAccepted(string contCID);

    IMintMeFactory  public _mintmefactory;
    MintMe          public _mintme;
    address payable public _stakeholder;
    uint256         public _extraFeeWei;
    mapping (string => address) public _pendings;

    constructor (address mintmefactory)
    {
        _mintmefactory = IMintMeFactory(mintmefactory);
        _stakeholder = payable(_msgSender());
    }

    function setExtraFee(uint256 extraFeeWei) public onlyOwner
    {
        _extraFeeWei = extraFeeWei;
    }

    function setMintMe(address mintme) public onlyOwner
    {
        // before or after this call the ownership of "mintme" contract
        // must be transferred to this contract
        _mintme = MintMe(mintme);
    }

    function withdrawMintMe() public onlyOwner
    {
        require(address(_mintme) != address(0), "PrivateMint: nothing to withdraw");
        Ownable(_mintme).transferOwnership(_msgSender());
        delete _mintme;
    }

    function mint(address to, string memory contCID) public payable
    {
        require(msg.value == _mintmefactory.feeWei() + _extraFeeWei, "PrivateMint: not enough funds");
        require(_pendings[contCID] == address(0), "PrivateMint: already has the same request");
        if (_extraFeeWei != 0)
        {
            _stakeholder.sendValue(_extraFeeWei / 2);
        }
        payable(owner()).sendValue(msg.value - _extraFeeWei / 2);
        _pendings[contCID] = to;
        emit RequestReceived(to, contCID);
    }

    function accept(string memory contCID) public payable onlyOwner returns(uint256)
    {
        require(address(_mintme) != address(0), "PrivateMint: no mintme");
        require(msg.value == _mintmefactory.feeWei(), "PrivateMint: not enough funds");
        require(_pendings[contCID] != address(0), "PrivateMint: no such request");
        uint256 tokenId = _mintme.mint{value: msg.value}(_pendings[contCID], contCID);
        delete _pendings[contCID];
        emit RequestAccepted(contCID);
        return tokenId;
    }

    function reject(string memory contCID) public onlyOwner
    {
        require(_pendings[contCID] != address(0), "PrivateMint: no such request");
        delete _pendings[contCID];
        emit RequestRejected(contCID);
    }
}