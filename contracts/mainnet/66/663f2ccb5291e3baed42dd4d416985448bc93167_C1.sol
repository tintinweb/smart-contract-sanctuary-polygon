/**
 *Submitted for verification at polygonscan.com on 2023-04-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

contract C1 {
   bool public solved;

   bytes public byteTest1 = "putCurEpochConPubKeyBytes";

   function putCurEpochConPubKeyBytes(bytes memory _bytes) public {
       require(msg.sender == address(this), "Not Owner");
       solved = true;
   }

   function executeCrossChainTx(bytes memory _method, bytes memory _bytes, bytes memory _bytes1, uint64 _num) public returns(bool success){
       (success, ) =address(this).call(abi.encodePacked(bytes4(keccak256(abi.encodePacked(_method, "(bytes)"))), abi.encode(_bytes, _bytes1, _num)));
   }

}