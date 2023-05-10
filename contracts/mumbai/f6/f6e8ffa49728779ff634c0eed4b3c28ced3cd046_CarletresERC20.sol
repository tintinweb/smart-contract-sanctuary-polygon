/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract CarletresERC20 {
   string public name = "CarletresERC20";
   
   uint256 public constant Max_Total_Supply = 80000;

   

   function setName(string memory newName) public {
       name = newName;
   }

   function getName() public view returns (string memory) {
       return name;
   }
}