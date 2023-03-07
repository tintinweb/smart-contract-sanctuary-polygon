// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


contract AAA {  

  function check() public returns(uint256) {

    if(10 < 50) {
        return 10;
    } else if (10 < 20) {
        return 1;
    } else {
        return 0;
    }
  }

  function check2() view public returns(uint256) {

    if(msg.sender == 0x37695157600C9d3Db2086cB4f14a33d1faD1A77C) {
        return 10;
    } else if (msg.sender == address(0)) {
        return 1;
    } else {
        return 0;
    }
  }
}