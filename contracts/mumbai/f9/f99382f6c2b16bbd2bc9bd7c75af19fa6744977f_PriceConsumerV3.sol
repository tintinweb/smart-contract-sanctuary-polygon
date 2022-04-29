/**
 *Submitted for verification at polygonscan.com on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract PriceConsumerV3 {
    
    function getLatestPrice() public view returns  (uint256) {
        return PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getLatestPrice() ;
    }
     function getLatestPrice2() public view returns  (uint256) {
        return PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getLatestPrice2();
    }    
     function getLatestPrice3() public view returns  (uint256) {
        return PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getLatestPrice3();
    }
     function getLatestPrice4() public view returns  (uint256) {
        return PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getLatestPrice4();
    } 

     function getBlockNumber() public view returns  (uint256) {
        return PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getBlockNumber();
    }             
    function getBlocktimestamp() public view returns   (uint256){
        return  PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getBlocktimestamp();
    }  
   function suma() public view returns   (uint256){
        return  PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getBlocktimestamp() + PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getLatestPrice4() + PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getBlockNumber() + PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getLatestPrice3() + PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getLatestPrice2() + PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getLatestPrice();
    }  


     
     uint hashDigits = 8;
      
    // Equivalent to 10^10
    uint hashModulus = 10 ** hashDigits; 
  
    // Function to generate the hash value
    function random10() public view returns   (uint256)
        
    {
        // "packing" the string into bytes and 
        // then applying the hash function. 
        // This is then typecasted into uint.
        uint random = 
             uint(keccak256(abi.encodePacked(suma())));
               
        // Returning the generated hash value 
        return random % hashModulus;
    } 
     uint hashDigits2 = 4;
      
    // Equivalent to 10^10
    uint hashModulus2 = 10 ** hashDigits2; 
  
    // Function to generate the hash value
    function random4() public view returns   (uint256)
        
    {
        // "packing" the string into bytes and 
        // then applying the hash function. 
        // This is then typecasted into uint.
        uint random = 
             uint(keccak256(abi.encodePacked(suma())));
               
        // Returning the generated hash value 
        return random % hashModulus;
    } 

       uint hashDigits3 = 2;
      
    // Equivalent to 10^10
    uint hashModulus3 = 10 ** hashDigits3; 
  
    // Function to generate the hash value
    function random2() public view returns   (uint256)
        
    {
        // "packing" the string into bytes and 
        // then applying the hash function. 
        // This is then typecasted into uint.
        uint random = 
             uint(keccak256(abi.encodePacked(suma())));
               
        // Returning the generated hash value 
        return random % hashModulus;
    } 
         uint hashDigits4 = 1;
      
    // Equivalent to 10^10
    uint hashModulus4 = 10 ** hashDigits4; 
  
    // Function to generate the hash value
    function random1() public view returns   (uint256)
        
    {
        // "packing" the string into bytes and 
        // then applying the hash function. 
        // This is then typecasted into uint.
        uint random = 
             uint(keccak256(abi.encodePacked(suma())));
               
        // Returning the generated hash value 
        return random % hashModulus;
    } 

}