// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint16 public num1;
    uint16 public num2;
    uint32 public num3;
    uint64 public num4;
    uint128 public num5;
    function setNum1(uint16 num) public {
        num1 = num;
    }
    function setNum2(uint16 num) public {
        num2 = num;
    }
    function setNum3(uint32 num) public {
        num3 = num;
    }
    function setNum4(uint64 num) public {
        num4 = num;
    }
    function setNum5(uint128 num) public {
        num5 = num;
    }

}