/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ShopMC {
    mapping(string => string) private shopToIpfs;
    mapping(string => address) private shopToOwner;
    mapping(address => string[]) private ownerToShops;

    event UserCountChanged(uint256);
    event ShopCountChanged(uint256);
    event ShopModified(string shopId, string ipfsHash);

    uint256 private shopCount = 0;
    uint256 private userCount = 0;

    function getShop(
        string memory _shopId
    ) public view returns (string memory) {
        return shopToIpfs[_shopId];
    }

    function getShopCount() public view returns (uint256) {
        return shopCount;
    }

    function getUserCount() public view returns (uint256) {
        return shopCount;
    }

    function getUserShops() public view returns (string[] memory) {
        return ownerToShops[msg.sender];
    }

    function updateShop(
        string memory _shopId,
        string memory _ipfsHash
    ) public {
        if (shopToOwner[_shopId] == address(0)) {
            shopToIpfs[_shopId] = _ipfsHash;
            shopToOwner[_shopId] = msg.sender;
            ownerToShops[msg.sender].push(_shopId);
            shopCount++;
            emit ShopCountChanged(shopCount);
        } else {
            require(
                shopToOwner[_shopId] == msg.sender,
                "You are not the owner of this shop"
            );
            shopToIpfs[_shopId] = _ipfsHash;
        }
        emit ShopModified(_shopId, _ipfsHash);
    }

    function deleteShop(string memory _shopId) public {
        require(
            shopToOwner[_shopId] == msg.sender,
            "You are not the owner of this shop"
        );
        delete shopToIpfs[_shopId];
        delete shopToOwner[_shopId];
        shopCount--;
        emit ShopCountChanged(shopCount);
    }
}