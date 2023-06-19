/**
 *Submitted for verification at polygonscan.com on 2023-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract RestaurantMenu {
    struct RestaurantInfo {
        string name;
        MenuItem[] menu;
    }

    struct MenuItem {
        string name;
        uint256 price;
        string ingredientsAndOrigins;
    }
    
    mapping(address => RestaurantInfo) public restaurants;
    
    function addRestaurant(string memory _name) public {
        restaurants[msg.sender].name = _name;
    }
    
    function addMenuItem(string memory _name, uint256 _price, string memory _ingredientsAndOrigins) public {
        restaurants[msg.sender].menu.push(MenuItem(_name, _price, _ingredientsAndOrigins));
    }
    
    function getRestaurant(address _restaurantAddress) public view returns (string memory) {
        return restaurants[_restaurantAddress].name;
    }
    
    function getMenu(address _restaurantAddress) public view returns (MenuItem[] memory) {
        return restaurants[_restaurantAddress].menu;
    }
}