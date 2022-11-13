/**
 *Submitted for verification at polygonscan.com on 2022-11-12
*/

pragma solidity ^0.7.2;

contract MyContract{

          function depositEth() public payable {
          //it will send the ethers to smart contract 
         }

         function getContractBal() public view returns (uint){
             return address(this).balance;
         }
}