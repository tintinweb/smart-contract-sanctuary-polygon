/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract Pixelverse2{   
       
    UserProfile user;
    address payable public ownerAddress;
    event PurchasedItem(uint256 amount, address account, string name);

    // structure to save user profile date
    struct UserProfile { 
        bytes32 username;
        bytes32 characterName;
        uint256 score;
    } 
    // modifier function will make other fucntions work only if msg sent by the owner
    modifier onlyOwner {
      require(msg.sender == ownerAddress);
      _;
   }

    // calls for the first time user creates instance of contract
    constructor() {
      ownerAddress = payable(msg.sender);   
    }


    receive() external payable {}

    // function to withdraw from the contract to the owner of contract
    function withdraw (uint _amount) external {
        require(msg.sender == ownerAddress, "only the owner of the contract can call this method");
        payable(msg.sender).transfer(_amount);
    }

    // get the balance available in the contract 
    function getBalance() external view returns (uint){
        return address(this).balance;
    }

    // PolygonTransfer method is to give rewards to the top players
    function PolygonTransfer(address payable recipient, uint amount) public returns(bool){
        require(ownerAddress == msg.sender, "transfer failed because you are not the owner."); // 
        if(amount <= address(msg.sender).balance) { 
            recipient.transfer(amount); 
            return true; 
        } else { 
            return false; 
        } 
    } 
    

    // PurchaseItem method is to give rewards to the top players 
    function PurchaseItem( uint amount, string calldata name) public returns(bool){ 
        //require(ownerAddress == msg.sender, "transfer failed because you are not the owner."); // 
        if(amount <= address(msg.sender).balance) { 
            ownerAddress.transfer(amount);
            emit PurchasedItem(amount, msg.sender, name);
            return true; 
        } else {
            return false;
        }
    }
}