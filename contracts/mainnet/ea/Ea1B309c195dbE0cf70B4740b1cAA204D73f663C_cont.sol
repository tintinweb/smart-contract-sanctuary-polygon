/**
 *Submitted for verification at polygonscan.com on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract owned {
     
    address payable owner; 
    modifier onlyOwner {
            require(
                msg.sender == owner,
                "Nothing For You!"
            );
            _;
        }    

    constructor()  {
        owner = payable(msg.sender);      
    }       
   
}

contract cont is owned {

    function register()public payable returns(bool) {
        //msg.value = amnt;
        require(msg.value>0,"Amount Should be greater then 0");        
        return true;
    }

    function withdraw(uint256 _amount) public payable onlyOwner returns (bool){
        payable(msg.sender).transfer(_amount);
        return true;
    }

     receive() payable external{ }
}