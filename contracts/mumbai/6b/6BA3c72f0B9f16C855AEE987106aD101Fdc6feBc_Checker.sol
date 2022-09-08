/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface ICollection {
    function items(uint256 _itemId) external view returns (string memory, uint256, uint256, uint256, address, string memory, string memory);
    function creator() external view returns (address);
    function globalManagers(address _user) external view returns (bool);
    function itemManagers(uint256 _itemId, address _user) external view returns (bool);
}

interface ITPRegistry {
    function isThirdPartyManager(string memory _thirdPartyId, address _manager) external view returns (bool);
    function thirdParties(string memory _tpID) external view returns (
        bool,
        bytes32,
        uint256,
        uint256,
        uint256,
        string memory,
        string memory
    );
}   


contract Checker {
    function validateWearables(
        address _sender,
        ICollection _collection, 
        uint256 _itemId,
        string memory _contentHash
    ) external view returns (bool) {
        bool hasAccess = false;

        address creator = _collection.creator();
        if (creator == _sender) {
            hasAccess = true;
        }

        if ( _collection.globalManagers(_sender)) {
            hasAccess = true;
        }

        if (_collection.itemManagers(_itemId, _sender)) {
           hasAccess = true;
        }

        if(!hasAccess) {
            return false;
        }

        (,,,,,,string memory contentHash) = _collection.items(_itemId);

       return keccak256(bytes(_contentHash)) == keccak256(bytes(contentHash));
    }

    function validateThirdParty(
        address _sender,
        ITPRegistry _tpRegistry, 
        string memory _tpId,
        bytes32 _root
    ) external view returns (bool) {
        if (!_tpRegistry.isThirdPartyManager(_tpId, _sender)) {
            return false;
        }

        (bool isApproved, bytes32 root,,,,,) = _tpRegistry.thirdParties(_tpId);

        return isApproved && root == _root;
    }
}