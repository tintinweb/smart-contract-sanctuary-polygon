/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface ICollection {
    function items(uint256 _itemId) external view returns (string memory, uint256, uint256, uint256, address, string memory, string memory);
    function creator() external returns (address);
    function globalManagers(address _user) external returns (bool);
    function itemManagers(uint256 _itemId, address _user) external returns (bool);
}


contract WearablesChecker {
    function validate(
        address _sender,
        ICollection _collection, 
        uint256 _itemId,
        string memory _contentHash
    ) external returns (bool) {
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

}