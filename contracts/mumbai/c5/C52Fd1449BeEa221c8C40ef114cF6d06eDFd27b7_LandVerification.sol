/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract LandVerification {

   address public landAdmin;
   mapping(string=>string) public details;
   constructor(){
       landAdmin=msg.sender;

   }
   function registerLand(string memory input, string memory output) public{
       require(landAdmin==msg.sender,"Caller is not Land Admin");
       details[input]=output;
   }
}