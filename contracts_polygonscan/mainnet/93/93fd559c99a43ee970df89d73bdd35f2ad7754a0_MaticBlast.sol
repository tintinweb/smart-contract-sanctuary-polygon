/**
 *Submitted for verification at polygonscan.com on 2022-02-09
*/

// contracts/MATICBlast.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MaticBlast {
    function blast(address[] calldata recipients)
        payable
        external
    {
      require(msg.value > 0, "Nothing to blast");
      uint256 to_each = msg.value / recipients.length;
      for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(to_each);
        }
      if (address(this).balance > 0){
          payable(msg.sender).transfer(address(this).balance);
      }
      
    }
}