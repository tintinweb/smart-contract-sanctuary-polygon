/**
 *Submitted for verification at polygonscan.com on 2023-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract GamePredict {
  event Log(string msg);
  
  receive() external payable  {
       // 當觸發receive()時，撰寫receive的訊息
       emit Log("receive");
   }

}