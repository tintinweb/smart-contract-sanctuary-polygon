/**
 *Submitted for verification at polygonscan.com on 2022-08-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

 contract SetStorage{

     uint256 public age;

     function setAge(uint256 _age) public {
         age = _age;
     }

     function getAge() public view returns(uint){
         return age;
     }


 }