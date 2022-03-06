/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

pragma solidity 0.5.4;

contract Simple {
     uint256 public totalSended;

     function sendAmount(address payable _user,uint256 amt) public payable
     {
         require(msg.value>0,"");
         _user.transfer(amt);
         totalSended+=amt;
     }
}