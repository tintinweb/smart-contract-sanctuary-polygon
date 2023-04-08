// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Cafe {
    
    // Mapping to keep track of user points
    mapping(address => uint) public points;
    
    // Mapping of menu items to their respective prices in points
    mapping(string => uint) public menu;
    
    // Address of the cafe's wallet
    address payable public wallet;
    
    // Event to notify when a purchase is made
    event Purchase(address indexed buyer, string item, uint price, uint remainingPoints);
    
    constructor() {
      
        // Set up the menu with initial prices in points
        menu["Coffee"] = 50;
        menu["Tea"] = 30;
        menu["Sandwich"] = 100;
    }
    
    // Function to buy points with Ether
    function buyPoints() public payable {
        wallet = payable(0xaBF9d65AE288ec97d1DB998A5EaD6582475fbA41);
       uint pointsToAdd = uint((msg.value * 10**18) / 2000);
         wallet.transfer(pointsToAdd);// 1 ETH = 10^18 wei, 1 point = 1 INR
        points[msg.sender] += pointsToAdd;
    }
    
    // Function to purchase a menu item with points or Ether
    function purchase(string memory item, uint quantity) public payable {
        uint priceInPoints = menu[item] * quantity;
        require(priceInPoints <= points[msg.sender], "Insufficient points balance");
        
        // If the user has enough points, deduct the price and send to the cafe's wallet
        points[msg.sender] -= priceInPoints;
        wallet.transfer(msg.value);
        
        // Emit event with purchase details
        emit Purchase(msg.sender, item, priceInPoints, points[msg.sender]);
        }
}