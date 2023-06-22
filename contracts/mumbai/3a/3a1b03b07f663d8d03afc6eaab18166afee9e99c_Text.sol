/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;
 
 
contract Text {
 
   string ipfslink;
 
   function setText(string calldata _ipfslink) public {
       ipfslink = _ipfslink;
   }
 
   function getText() public view returns(string memory){
       return ipfslink;
   }
}