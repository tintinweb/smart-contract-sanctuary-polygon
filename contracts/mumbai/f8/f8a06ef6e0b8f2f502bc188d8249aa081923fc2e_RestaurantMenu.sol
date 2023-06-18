/**
 *Submitted for verification at polygonscan.com on 2023-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract RestaurantMenu {
    struct Restaurant {
        string name;
        address addr;
    }

    struct MenuItem {
        string name;
        uint256 price;
        string ingredientsAndOrigins;
    }
    
    mapping(address => Restaurant) public restaurants;
    mapping(address => MenuItem[]) public restaurantMenus;
    
    function addRestaurant(string memory _name) public {
        restaurants[msg.sender] = Restaurant(_name, msg.sender);
    }
    
    function addMenuItem(string memory _name, uint256 _price, string memory _ingredientsAndOrigins) public {
        restaurantMenus[msg.sender].push(MenuItem(_name, _price, _ingredientsAndOrigins));
    }
    
    function getRestaurant(address _restaurantAddress) public view returns (string memory, address) {
        Restaurant memory restaurant = restaurants[_restaurantAddress];
        return (restaurant.name, restaurant.addr);
    }
    
    function getMenu(address _restaurantAddress) public view returns (MenuItem[] memory) {
        return restaurantMenus[_restaurantAddress];
    }
}