/**
 *Submitted for verification at polygonscan.com on 2023-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract RestaurantSupplyChain {
    struct FoodItem {
        uint256 itemId;
        string name;
        string origin;
        address[] supplyChain;
    }
    
    mapping(uint256 => FoodItem) private foodItems;
    
    uint256 private currentItemId;
    
    event FoodItemAdded(uint256 itemId, string name, string origin);
    
    function addFoodItem(string memory _name, string memory _origin) public {
        currentItemId++;
        FoodItem storage newItem = foodItems[currentItemId];
        newItem.itemId = currentItemId;
        newItem.name = _name;
        newItem.origin = _origin;
        newItem.supplyChain.push(msg.sender);
        
        emit FoodItemAdded(currentItemId, _name, _origin);
    }
    
    function getFoodItem(uint256 _itemId) public view returns (string memory name, string memory origin, address[] memory supplyChain) {
        require(_itemId <= currentItemId, "Invalid item ID");
        
        FoodItem storage item = foodItems[_itemId];
        return (item.name, item.origin, item.supplyChain);
    }
}