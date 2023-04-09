// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Cafe  {
    
    // Mapping to keep track of user points
    mapping(address => uint) public points;
    mapping (address=>uint) public badges;
    
    // Mapping of menu items to their respective prices in points
    mapping(string => uint) public menu;
    
    // Address of the cafe's wallet
    address payable owner = payable(0xaBF9d65AE288ec97d1DB998A5EaD6582475fbA41);
    
    // Event to notify when a purchase is made
    event Purchase(address indexed buyer, string item, uint price, uint remainingPoints);
    
    constructor() {
      
       
        menu["Coffee"] = 50;
        menu["Tea"] = 30;
        menu["Sandwich"] = 100;
    }
    
 
  function buyPoints() public payable  {
   
 
    owner.transfer(msg.value); 
   
 

}
function test () public payable{
    
}
    
    // Function to purchase a menu item with points or Ether
    function purchase(uint price) public payable {
        
   
        
        
        
        owner.transfer((price)*65/100000);
        
        
        
        }
}