/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

// SPDX-License-Identifier: None
pragma solidity ^0.6.0;

contract calculator{
    string public creator="Ritesh";
    address public owner;

    constructor() public{
        owner=msg.sender;
    }

    modifier allowOnlyOwner() {
        require(owner==msg.sender);
        _;
    }

    function  add(uint num1,uint num2)  public view returns (uint){
        uint c=num1+num2;
        return c;
    }

    function sub(int x_,int y_) public view returns(int){
        return x_-y_;
    }

    function mul(int x_,int y_) public view  allowOnlyOwner returns(int){
        return x_*y_;
    }

    function div(int x_,int y_) public view returns(int){
        return x_/y_;
    }
}