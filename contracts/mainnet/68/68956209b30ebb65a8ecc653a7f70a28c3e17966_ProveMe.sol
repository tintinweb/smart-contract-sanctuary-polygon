/*
This file is part of the Prover project.

The Prover Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The Prover Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the Prover Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/
// SPDX-License-Identifier: GNU lesser General Public License

pragma solidity ^0.8.0;

import "Ownable.sol";
import "Address.sol";


contract ProveMe is Ownable
{
    using Address for address payable;

    event FeeChanged(uint256 feeWei);
    event Requested(string cid);
    event Submited(string cid, bool proven, string cidJson);
    event Discarded(string cid);

    uint256 private                   _feeWei;
    address payable private           _fundsReceiver;
    mapping(address => bool ) private _blessed;

    enum Status
    {
        Unknown,
        Pending,
        Proved,
        NotProved
    }

    struct CIDInfo
    {
        Status status;
        string cidJson;
    }
    mapping(string => CIDInfo) public _CIDtoInfo;

    constructor()
    {
        setFee(1 ether);
        _fundsReceiver = payable(_msgSender());
    }

    function bless(address b) public onlyOwner
    {
        _blessed[b] = true;
    }

    function curse(address b) public onlyOwner
    {
        delete _blessed[b];
    }

    modifier blessedOrOwner()
    {
        require(_msgSender() == owner() || _blessed[_msgSender()]);
        _;
    }

    function setFee(uint256 feeWei) public onlyOwner
    {
        _feeWei = feeWei;
        emit FeeChanged(_feeWei);
    }

    function fee() public view returns(uint256)
    {
        return _feeWei;
    }

    function setFundsReceiver(address fr) public onlyOwner
    {
        require(fr != address(0), "ProveMe: zero address");
        _fundsReceiver = payable(fr);
    }

    function fundsReceiver() public view returns(address payable)
    {
        return _fundsReceiver;
    }

    function request(string memory cid) public payable
    {
        CIDInfo storage info = _CIDtoInfo[cid];
        require(info.status == Status.Unknown, "ProveMe: duplicate cid");
        require(msg.value == _feeWei, "ProveMe: invalid payment value");
        _fundsReceiver.sendValue(_feeWei);
        info.status = Status.Pending;
        emit Requested(cid);
    }

    function submit(string memory cid, bool proven, string memory cidJson) public blessedOrOwner
    {
        CIDInfo storage info = _CIDtoInfo[cid];
        require(info.status != Status.Unknown, "b1efb0f4-f01c-4fae-aa81-d650b8b7964d");
        require(info.status == Status.Pending, "5bf4da3d-3396-4e3c-b59f-f9eb83aad7cc");
        info.status = proven ? Status.Proved : Status.NotProved;
        info.cidJson = cidJson;
        emit Submited(cid, proven, cidJson);
    }

    function discard(string memory cid) public blessedOrOwner
    {
        CIDInfo storage info = _CIDtoInfo[cid];
        require(info.status != Status.Unknown, "ProveMe: unknown cid");
        delete _CIDtoInfo[cid];
        emit Discarded(cid);
    }
}