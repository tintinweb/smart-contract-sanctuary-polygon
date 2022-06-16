/**
 *Submitted for verification at polygonscan.com on 2022-06-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Test{
    address[] public owners;
  
  function setOwners(address[] memory _owners) public  {
    owners = _owners;
  }

  function getOwners() public view returns(address[] memory){
      return owners;
  }
}