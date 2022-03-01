/**
 *Submitted for verification at polygonscan.com on 2022-03-01
*/

// SPDX-License-Identifier: GPL-3.0

// File: contracts/test.sol



pragma solidity >=0.7.0 <0.9.0;


contract test {
  uint256 public START;
     uint256[] RandomID;
     uint256[] RandomID2;
  constructor(
  ) {
    START = block.timestamp;
        RandomID_get();
  }
    
     function RandomID_get() public returns(uint256[] memory){
         for (uint256 i = 1; i <= 8; i++) {
             RandomID.push(i);
         }
         return RandomID;
    }
    function RandomID_get2() public returns(uint256[] memory){
         for (uint256 i = 1; i <= 8; i++) {
             RandomID2.push(random2());
         }
         return RandomID2;
    }
     function excludeID(uint tokenID) public returns (uint256){
        uint i = 0;
        uint newID;
        tokenID -=1;
        while(true){
            require(i<8, "limit out");
           if ((i+tokenID) <=8 ) { 
            if( RandomID[i+tokenID] != 0 ){
                newID = RandomID[i+tokenID];
                RandomID[i+tokenID] = 0;
                break;
            } }
            else{
                if ((tokenID-i) >= 0) {
                if (RandomID[tokenID-i] != 0 ){
                newID = RandomID[tokenID-i-1];
                RandomID[tokenID-i] = 0;
                break;
            }}
        }
          i++;
    }
    return newID;
    }
   function random() public view returns (uint) {
    uint randomHash = uint(keccak256(abi.encodePacked(block.timestamp))) % 8+1;
    return randomHash;
    } 
     function random2() public  returns (uint) {
          uint randomHash2 = random();
    uint randomHash = excludeID(randomHash2);
    return randomHash;
    } 
}