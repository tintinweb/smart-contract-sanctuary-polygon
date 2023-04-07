// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WhiteListed {

address public owner;

   // Mapping to keep track of whitelisted addresses
   mapping(address=>bool) public whitelist;

   // Constructor function to set the contract owner
   constructor(){
       owner = msg.sender;
    }

    // Modifier to restrict function access to contract owner only
    modifier onlyOwner(){
    require(msg.sender == owner ,"Only owner can call this function");
    _;
    }

    // Function to add an address to the whitelist, which can only be called by the contract owner
    function addWhitelistuser(address user) public onlyOwner{
        whitelist[user]= true;
    }

    // Function to remove an address from the whitelist, which can only be called by the contract owner
    function removeWhiteListUser(address user) public onlyOwner{
        whitelist[user] = false;
    }

    // Function to check if an address is whitelisted or not
    function checkWhitelistuser(address user) public view returns (bool){
        return whitelist[user];
    }

}