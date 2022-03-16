/**
 *Submitted for verification at polygonscan.com on 2022-03-16
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract Fu1 {
   
    function test() public virtual returns(string memory){
        return "Fu1";
    }

    

}


contract Fu2 {

    address owner;

    uint256 num;

    constructor(){
        owner = msg.sender;
        num=100;
    }

    modifier only(){
        require(msg.sender==owner,unicode"错误");
        _;
    }
   
    function test() public view only  returns (uint256 ){
            return num;
    }

}