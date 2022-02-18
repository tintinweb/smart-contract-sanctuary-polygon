/**
 *Submitted for verification at polygonscan.com on 2022-02-17
*/

// File: contracts/Encode.sol


pragma solidity ^0.8.7;

contract Encode 
{
    // We want hash to be of 8 digits 
    // hence we store 10^8 which is 
    // used to extract first 8 digits 
    // later by Modulus 
    uint hashDigits = 8;
      
    // Equivalent to 10^8 = 8
    uint hashModulus = 10 ** hashDigits; 
  
    // Function to generate the hash value
    function _generateRandom(string memory _str) 
        public view returns (uint) 
    {
        // "packing" the string into bytes and 
        // then applying the hash function. 
        // This is then typecasted into uint.
        uint random = 
             uint(keccak256(abi.encodePacked(_str)));
               
        // Returning the generated hash value 
        return random;
    }

    bytes32 public answer =
        0x60298f78cc0b47170ba79c10aa3851d7648bd96f2f8e46a19dbc777c36fb0c00;

    // Magic word is "Solidity"
    function guess(string memory _word) public view returns (bool) {
        return keccak256(abi.encodePacked(_word)) == answer;
    }

    function show(string memory _word) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_word));
    }
  
}