//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TestMulticall {

    uint8 public value1;
    uint8 public value2;

    event Value1Set(uint8 value);
    event Value2Set(uint8 value);
    
    // *************** Get/Set *****************
    function getValue1() public virtual view returns (uint8) {
        return value1;
    }
    function getValue2() public virtual view returns (uint8) {
        return value2;
    }
    
    function multicall(uint8 value) public returns (uint8) {
        require(value > 10, "Value should be higher than 10");
        value = functionA(value);
        value1 = value + 5;
        value2 = functionB(value1);

        emit Value1Set(value1);
        emit Value2Set(value2);

        return value2;
    }

    function functionA(uint8 value) pure public returns (uint8) {
        return value * 2;
    }

    function functionB(uint8 value) pure public returns (uint8) {
        return value -3;
    }

}