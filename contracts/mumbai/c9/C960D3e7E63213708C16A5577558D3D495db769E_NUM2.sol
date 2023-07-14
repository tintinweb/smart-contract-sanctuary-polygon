// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract NUM2 {
    uint256 public num ;

function setNum(uint256 _num) public  {
    num=_num;
}
function getNum() public view returns(uint256){
    return num;
}
function mulNUm()public{
    num=num*2;
}

   
}