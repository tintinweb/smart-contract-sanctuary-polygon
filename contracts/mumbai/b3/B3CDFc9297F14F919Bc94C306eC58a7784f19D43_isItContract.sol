// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.0;
contract isItContract {
    function contractAddress() public view returns (address) {  
       address contAddress = address(this); //contract address  
       return contAddress;  
    }  
}