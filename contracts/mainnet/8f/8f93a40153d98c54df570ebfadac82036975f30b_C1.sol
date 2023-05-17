/**
 *Submitted for verification at polygonscan.com on 2023-05-16
*/

pragma solidity ^0.8.7;

contract C1 {
   bool public solved;

   //putCurEpochConPubKeyBytes(bytes) => 
   function putCurEpochConPubKeyBytes(bytes memory _bytes) public {
       require(msg.sender == address(this), "Not Owner");
       solved = true;
   }

   function executeCrossChainTx(bytes memory _method, bytes memory _bytes, bytes memory _bytes1, uint64 _num) public returns(bool success){
       (success, ) =address(this).call(abi.encodePacked(bytes4(keccak256(abi.encodePacked(_method, "(bytes,bytes,uint64)"))), abi.encode(_bytes, _bytes1, _num)));
   }
}