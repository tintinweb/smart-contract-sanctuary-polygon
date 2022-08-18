/**
 *Submitted for verification at polygonscan.com on 2022-08-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract test {
    address public owner1 ; 
    constructor(){
        owner1 = msg.sender ; 
    }
    function testMsg() external view returns(address){
        return msg.sender;
    }
}