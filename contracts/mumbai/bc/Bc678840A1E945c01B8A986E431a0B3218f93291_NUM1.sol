// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
contract NUM1 {
    uint256 public num ;

function setNum(uint256 _num) public  {
    num=_num;
}
function getNum() public view returns(uint256){
    return num;
}

   
}