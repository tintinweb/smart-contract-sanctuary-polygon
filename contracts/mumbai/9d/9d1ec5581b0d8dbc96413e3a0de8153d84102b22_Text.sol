/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;
 
 
contract Text {
 
   string public ipfslink;
   uint public dataId;

 
   function setText(uint _dataId,string calldata _ipfslink) public {
       ipfslink = _ipfslink;
       dataId = _dataId;
   }

}