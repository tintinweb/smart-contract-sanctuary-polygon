/**
 *Submitted for verification at polygonscan.com on 2023-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract RestaurantMenu {
    
    struct MenuItem {
        string name;
        uint256 price;
        string ingredientsAndOrigins;
    }
    
    mapping(address => MenuItem[]) public restaurantMenus;
    
    function addMenuItem(string memory _name, uint256 _price, string memory _ingredientsAndOrigins) public {
        restaurantMenus[msg.sender].push(MenuItem(_name, _price, _ingredientsAndOrigins));
    }
    
    function getMenu(address _restaurantAddress) public view returns (MenuItem[] memory) {
        return restaurantMenus[_restaurantAddress];
    }
}