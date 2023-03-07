// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


contract AAA {  

  function check() public returns(bool) {

    uint counter = 0;
    if(msg.sender == 0x37695157600C9d3Db2086cB4f14a33d1faD1A77C) {
        ++counter;
        return true;
    } else {
        counter *=2 ;
        return false;
    }
  }

  function check2() view public returns(bool) {

    uint counter = 0;
    if(msg.sender == 0x37695157600C9d3Db2086cB4f14a33d1faD1A77C) {
        ++counter;
        return true;
    } else {
        counter *=2 ;
        return false;
    }
  }
}