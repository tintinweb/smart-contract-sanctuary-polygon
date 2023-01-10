//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.0;

contract addValue{
    uint public data;

    function setValue(uint _data) external returns(uint finalValue){
        data = _data;
        finalValue = data;
        return finalValue;
    }
}