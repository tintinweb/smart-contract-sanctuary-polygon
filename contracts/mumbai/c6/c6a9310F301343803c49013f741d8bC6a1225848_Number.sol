// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Number {
    uint number;
    //event getTheNumber(uint);

    function setNumber(uint _number) external {
        number = _number;
    }

    function getNumber() external view returns(uint) {
        //emit getTheNumber(number);
        return number;
    }
}