/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: null
pragma solidity ^0.8.1;

//define the contract
contract crypto_lottery_owners{
    
    //create an owner of the contract funds called boss
    address payable public boss=payable(0xc14482897aC3c8C2b80cF64b9cDa9E84415c0069);

    //price varaible, with intial setting. 
    uint public price= 20000000000000000;


    //store owners
    mapping (address => bool) public owners;

    //add owner
    function add_owner(address _userAddress) public payable {
        require(msg.value >= price);
        owners[_userAddress] = true;
    }
    
    //set boss as an owner
    constructor(){
        owners[boss] = true;
    }

    //check owner
    function is_owner(address _userAddress) public view returns (bool) {
        if(_userAddress==boss){
            return true;
        }else{
            return owners[_userAddress];
        }
        
    }

    //Send funds out by boss
    function sendFundsOut(address payable _paytoAddress, uint256 _amount) public {
        require(msg.sender == boss);
        require(_amount<=address(this).balance);
        _paytoAddress.transfer(_amount);
    }

    //set price by boss
    function change_price(uint256 _new_price) public{
        require(msg.sender == boss);
        price=_new_price;
    }

    //Transfer the boss seat
    function transferBoss(address payable newBoss) public {
        require(msg.sender == boss);
        owners[newBoss] = true; //set new boss as an owner
        boss = newBoss;
    }

    //check balance of the contract
    function checkBalance() public view returns (uint256) {
        return address(this).balance;
    }


}

//mumbai    0xD82eeEb1D6c06358E351079AB821b4Cfdc3D69dc