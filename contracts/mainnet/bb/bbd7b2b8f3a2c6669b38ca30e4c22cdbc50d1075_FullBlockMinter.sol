/**
 *Submitted for verification at polygonscan.com on 2023-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract FullBlockMinter {
  address public owner;
  uint256 public gasGuzzler;

  constructor(address newOwner){
    owner = newOwner;
  }

  modifier onlyOwner(){
    require(msg.sender == owner, "only owner");
    _;
  }

  function setOwner(address newOwner) external onlyOwner{
    owner = newOwner;
  }

  function mint(address target, uint256 value, bytes memory data) external onlyOwner {
    (bool success, ) = target.call{value: value}(data);
    require(success, "external call failed");

    while (gasleft() > 1000){
      gasGuzzler += 1;
      gasGuzzler -= 1;
    }
  }
}