/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract AAA {
  uint myCounter = 10;

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

  function check3() public view returns(uint) {
    if(msg.sender == 0x37695157600C9d3Db2086cB4f14a33d1faD1A77C) {
        return myCounter;
    } else {
        return 0;
    }
  }

  function check4() public view returns(uint) {
    if(tx.origin == 0x37695157600C9d3Db2086cB4f14a33d1faD1A77C) {
        return myCounter;
    } else {
        return 0;
    }
  }
}