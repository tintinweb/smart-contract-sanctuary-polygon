// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MyContract {
  address public admin;

  constructor () {
    admin = 0xf85FEB0FE0CC2B0166f6f32d2121631710727Bc7;
  }

  function lilVitalik(uint256 bro) public payable returns(uint256){
    return bro;
  }

  function booly(uint num) public pure returns(bool) {
    return num % 2 == 0;
  }

function trollAdd(uint256 a, uint256 b) public pure returns (uint256) {
    return a + b;
}

  function brother() public {
    require(admin == msg.sender, "jkbsdnsdd");
    admin = msg.sender;
  }
}