//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract AgeCounter{
    uint age = 10;
    function getAge() public view returns(uint){
        return age;
    }
    function setAge() public{
        age = age+1;
    }
}