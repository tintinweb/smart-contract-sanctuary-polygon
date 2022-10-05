// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Number {

uint256 number ;

event increaseNumbers (address User,uint256 number);
event DecreaseNumbers (address User,uint256 number);

function increaseNumber () external {
    number++;
 emit increaseNumbers (msg.sender,number);
}

function decreaseNumber () external {
    number--;
 emit DecreaseNumbers (msg.sender,number);
}

function getNumber () external view returns (uint256){
    return number;
}






}